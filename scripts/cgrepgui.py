import sys
import os
import subprocess
import clang.cindex
from PyQt5 import QtWidgets, QtCore, QtGui
import logging
import tempfile
import argparse

# Configuration variables
BROWSER_COMMAND = "nautilus"  # External file browser command (change as needed)

# Configure logging for debugging purposes.
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')

def load_directory(dir_path, recursive=False):
    """
    Returns a list of .c and .h file paths contained in the directory.
    If recursive is True, searches subdirectories recursively.
    """
    files = []
    if recursive:
        for root, dirs, filenames in os.walk(dir_path):
            for f in filenames:
                if f.endswith('.c') or f.endswith('.h'):
                    files.append(os.path.join(root, f))
    else:
        try:
            for f in os.listdir(dir_path):
                full_path = os.path.join(dir_path, f)
                if os.path.isfile(full_path) and (f.endswith('.c') or f.endswith('.h')):
                    files.append(full_path)
        except Exception as e:
            logging.error(f"Error listing directory {dir_path}: {e}")
    return files

def parse_command_line_arguments():
    """
    Processes command line arguments using argparse.
    
    Returns a tuple containing:
    - file_list: list of files to process
    - filter_macros: boolean indicating whether to filter macros
    - macro_prefixes: list of macro prefixes to filter
    """
    parser = argparse.ArgumentParser(description='C Identifier Explorer - Browse and search C code identifiers')
    
    # Opzioni per il livello di log
    parser.add_argument('-l', '--loglevel', 
                        choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'],
                        default='INFO',
                        help='Set the logging level')
    
    # Opzioni per la ricorsione
    parser.add_argument('-R', '--recursive', 
                        action='store_true',
                        help='Load all directories recursively (global flag)')
    
    parser.add_argument('-r', '--recursive-dir', 
                        action='append',
                        metavar='DIR',
                        help='Load the specified directory recursively')
    
    # Opzioni per il filtraggio delle macro
    parser.add_argument('--no-filter-macros', 
                        action='store_false',
                        dest='filter_macros',
                        help='Disable filtering of macros (by default, macros with certain prefixes are filtered out)')
    
    parser.add_argument('--macro-prefixes', 
                        nargs='+',
                        default=['__'],
                        help='List of macro prefixes to filter out (default: "__")')
    
    # Argomenti posizionali per i file e le directory
    parser.add_argument('paths', 
                        nargs='*',
                        help='Files or directories to process')
    
    args = parser.parse_args()
    
    # Imposta il livello di log
    numeric_level = getattr(logging, args.loglevel.upper(), None)
    if not isinstance(numeric_level, int):
        raise ValueError(f"Invalid log level: {args.loglevel}")
    logging.getLogger().setLevel(numeric_level)
    
    # Elabora i file e le directory
    file_list = []
    recursive_dirs = args.recursive_dir or []
    
    for path in args.paths:
        if os.path.isdir(path):
            # Determina se la directory deve essere caricata ricorsivamente
            recursive = args.recursive or path in recursive_dirs
            logging.info(f"Loading directory: {path} (recursive={recursive})")
            files = load_directory(path, recursive)
            file_list.extend(files)
        elif os.path.isfile(path):
            logging.info(f"Loading file: {path}")
            file_list.append(path)
        else:
            logging.warning(f"Argument {path} is neither a valid file nor directory. Skipped.")
    
    return file_list, args.filter_macros, args.macro_prefixes

def traverse_ast(cursor, results, input_files, filter_macros=True, macro_prefixes=None):
    """
    Recursively traverse the AST and collect information about C objects.
    Only process nodes belonging to the input files.
    
    Args:
        cursor: The current cursor in the AST
        results: List to store the collected results
        input_files: List of input files to process
        filter_macros: Whether to filter out macros with certain prefixes
        macro_prefixes: List of macro prefixes to filter out
    """
    if macro_prefixes is None:
        macro_prefixes = ['__']
        
    try:
        file_name = cursor.location.file.name if cursor.location.file else None
    except Exception as e:
        logging.error(f"Error getting file name for cursor '{cursor.spelling}': {e}")
        file_name = None

    if file_name and not any(file_name.endswith(f) for f in input_files):
        pass
    else:
        if cursor.kind in [
            clang.cindex.CursorKind.MACRO_DEFINITION,
            clang.cindex.CursorKind.FUNCTION_DECL,
            clang.cindex.CursorKind.TYPEDEF_DECL,
            clang.cindex.CursorKind.PARM_DECL,
            clang.cindex.CursorKind.STRUCT_DECL,
            clang.cindex.CursorKind.ENUM_DECL,
            clang.cindex.CursorKind.ENUM_CONSTANT_DECL,
            clang.cindex.CursorKind.FIELD_DECL,
            clang.cindex.CursorKind.VAR_DECL,        # Global variables (and locals)
            clang.cindex.CursorKind.UNION_DECL       # Union declarations
        ]:
            # Filtra le macro se richiesto
            if filter_macros and cursor.kind == clang.cindex.CursorKind.MACRO_DEFINITION:
                name = cursor.spelling
                if any(name.startswith(prefix) for prefix in macro_prefixes):
                    # Salta questa macro perché inizia con un prefisso da filtrare
                    logging.debug(f"Filtered out macro: {name}")
                    pass
                else:
                    # Aggiungi la macro perché non corrisponde ai prefissi da filtrare
                    record = create_record(cursor, file_name)
                    results.append(record)
                    logging.debug(f"Record added: {record}")
            else:
                # Per tutti gli altri tipi, aggiungi sempre il record
                record = create_record(cursor, file_name)
                results.append(record)
                logging.debug(f"Record added: {record}")
    
    for child in cursor.get_children():
        traverse_ast(child, results, input_files, filter_macros, macro_prefixes)
def create_record(cursor, file_name):
    """Create a record for the given cursor."""
    record = {}
    record["Type"] = str(cursor.kind).split('.')[-1]
    record["Name"] = cursor.spelling
    record["File"] = file_name if file_name else ""
    record["Line"] = cursor.location.line if cursor.location.line else 0
    record["Column"] = cursor.location.column if cursor.location.column else 0
    
    # Determina se l'elemento è anonimo
    is_anonymous = not cursor.spelling or cursor.spelling == ""
    
    # Per le union e struct annidate, potrebbero avere un nome vuoto ma essere referenziate tramite un campo
    if is_anonymous and cursor.kind in [clang.cindex.CursorKind.STRUCT_DECL, clang.cindex.CursorKind.UNION_DECL]:
        # Se non ha un nome, è anonima
        record["IsAnonymous"] = True
        # Per le strutture anonime, aggiungiamo un nome descrittivo che include "unnamed at <file>:<line>"
        record["Name"] = f"unnamed at {os.path.basename(file_name)}:{cursor.location.line}"
    else:
        record["IsAnonymous"] = is_anonymous
    
    # Informazioni di base per il campo Details
    if cursor.kind == clang.cindex.CursorKind.FUNCTION_DECL:
        record["Details"] = cursor.type.spelling
    elif cursor.kind == clang.cindex.CursorKind.PARM_DECL:
        record["Details"] = cursor.type.spelling
    elif cursor.kind == clang.cindex.CursorKind.TYPEDEF_DECL:
        record["Details"] = cursor.underlying_typedef_type.spelling
    elif cursor.kind == clang.cindex.CursorKind.FIELD_DECL:
        record["Details"] = cursor.type.spelling
    elif cursor.kind == clang.cindex.CursorKind.ENUM_CONSTANT_DECL:
        record["Details"] = f"Value: {cursor.enum_value}"
    elif cursor.kind == clang.cindex.CursorKind.VAR_DECL:
        # For variables, show the type and whether it is const
        details = cursor.type.spelling
        if "const" in details:
            details += " (const)"
        record["Details"] = details
    elif cursor.kind == clang.cindex.CursorKind.UNION_DECL:
        # For unions, optionally list member types if desired.
        record["Details"] = "Union declaration"
    else:
        record["Details"] = ""
    
    # Aggiungi la dichiarazione completa C
    record["Declaration"] = extract_full_declaration(cursor)
    
    return record

def extract_full_declaration(cursor):
    """
    Estrae la dichiarazione completa C per un cursore.
    Questo è un tentativo di ricostruire la dichiarazione originale.
    """
    try:
        # Ottieni l'estensione del cursore (inizio e fine)
        start = cursor.extent.start
        end = cursor.extent.end
        
        if not start.file or not end.file:
            return ""
            
        # Leggi il file sorgente
        with open(start.file.name, 'r') as f:
            source_lines = f.readlines()
        
        # Estrai le linee rilevanti
        if start.line == end.line:
            # Dichiarazione su una singola linea
            line = source_lines[start.line - 1]
            declaration = line[start.column - 1:end.column - 1].strip()
        else:
            # Dichiarazione su più linee
            declaration_lines = []
            
            # Prima linea (dalla colonna di inizio fino alla fine)
            first_line = source_lines[start.line - 1]
            declaration_lines.append(first_line[start.column - 1:].rstrip())
            
            # Linee intermedie (complete)
            for line_num in range(start.line, end.line - 1):
                declaration_lines.append(source_lines[line_num].rstrip())
            
            # Ultima linea (dall'inizio fino alla colonna di fine)
            last_line = source_lines[end.line - 1]
            declaration_lines.append(last_line[:end.column - 1].rstrip())
            
            declaration = '\n'.join(declaration_lines)
        
        # Per alcune dichiarazioni, potremmo voler aggiungere un punto e virgola se manca
        if cursor.kind in [clang.cindex.CursorKind.STRUCT_DECL, 
                          clang.cindex.CursorKind.ENUM_DECL, 
                          clang.cindex.CursorKind.UNION_DECL,
                          clang.cindex.CursorKind.TYPEDEF_DECL,
                          clang.cindex.CursorKind.VAR_DECL] and not declaration.endswith(';'):
            declaration += ';'
            
        return declaration
    except Exception as e:
        logging.error(f"Error extracting declaration for {cursor.spelling}: {e}")
        return ""
    
def process_files(file_list, filter_macros=True, macro_prefixes=None):
    """
    Process a list of C/C++ files, parse them with clang, and collect all C objects.
    
    Args:
        file_list: List of files to process
        filter_macros: Whether to filter out macros with certain prefixes
        macro_prefixes: List of macro prefixes to filter out
    """
    if macro_prefixes is None:
        macro_prefixes = ['__']
        
    index = clang.cindex.Index.create()
    all_results = []
    
    # Dizionario per tenere traccia degli elementi già processati
    # La chiave è una tupla (tipo, nome, file, linea)
    processed_items = {}
    
    for f in file_list:
        logging.info(f"Processing file: {f}")
        tu = index.parse(f, args=['-std=c99', '-Xclang', '-detailed-preprocessing-record'])
        
        # Risultati temporanei per questo file
        file_results = []
        traverse_ast(tu.cursor, file_results, file_list, filter_macros, macro_prefixes)
        
        # Filtra i duplicati prima di aggiungerli ai risultati finali
        for record in file_results:
            # Crea una chiave univoca per ogni record
            key = (
                record.get("Type", ""),
                record.get("Name", ""),
                record.get("File", ""),
                record.get("Line", 0)
            )
            
            # Se questo elemento non è già stato processato, aggiungilo ai risultati
            if key not in processed_items:
                processed_items[key] = record
                all_results.append(record)
            else:
                logging.debug(f"Skipping duplicate: {key}")
    
    logging.info("Finished processing files.")
    return all_results


class ReadOnlyCheckBoxDelegate(QtWidgets.QStyledItemDelegate):
    """
    Un delegato personalizzato che mostra una casella di controllo per i valori booleani,
    ma non permette di modificarli (sola lettura).
    """
    def __init__(self, parent=None):
        super(ReadOnlyCheckBoxDelegate, self).__init__(parent)
        
    def createEditor(self, parent, option, index):
        # Non creiamo un editor perché è di sola lettura
        return None
        
    def paint(self, painter, option, index):
        # Ottieni il valore booleano dalla cella
        value = index.data(QtCore.Qt.DisplayRole)
        checked = False
        
        if isinstance(value, bool):
            checked = value
        elif isinstance(value, str):
            checked = value.lower() in ('true', 'yes', '1', 'on')
        elif isinstance(value, int):
            checked = bool(value)
            
        # Configura lo stile
        opt = QtWidgets.QStyleOptionButton()
        opt.rect = option.rect
        opt.state = QtWidgets.QStyle.State_Enabled
        
        if checked:
            opt.state |= QtWidgets.QStyle.State_On
        else:
            opt.state |= QtWidgets.QStyle.State_Off
            
        # Centra la checkbox
        checkbox_size = option.widget.style().subElementRect(
            QtWidgets.QStyle.SE_CheckBoxIndicator, opt, option.widget).size()
        opt.rect.setLeft(option.rect.center().x() - checkbox_size.width() // 2)
        
        # Disegna la checkbox
        option.widget.style().drawControl(QtWidgets.QStyle.CE_CheckBox, opt, painter, option.widget)

class CustomFilterProxy(QtCore.QSortFilterProxyModel):
    """
    A custom filter proxy that filters rows based on:
      1. The search type, directory, and filename (if not "*" then the row must match the selected value).
      2. The search text applied across all columns.
    """
    def __init__(self, parent=None):
        super(CustomFilterProxy, self).__init__(parent)
        self.search_type = "*"
        self.search_directory = "*"
        self.search_file = "*"
        self.search_named = "*"  
        self.search_mode = "*"

    def setSearchMode(self, search_mode):
        self.search_mode = search_mode
        self.invalidateFilter()

    def setSearchNamed(self, search_named):  # Nuovo metodo per impostare il filtro Named
        self.search_named = search_named
        self.invalidateFilter()

    def setSearchType(self, search_type):
        self.search_type = search_type
        self.invalidateFilter()
    
    def setSearchDirectory(self, search_directory):
        self.search_directory = search_directory
        self.invalidateFilter()
    
    def setSearchFile(self, search_file):
        self.search_file = search_file
        self.invalidateFilter()
        
    def filterAcceptsRow(self, source_row, source_parent):
        model = self.sourceModel()
        if self.search_type != "*":
            index = model.index(source_row, 0, source_parent)
            if model.data(index) != self.search_type:
                return False
        if self.search_named != "*":
            index = model.index(source_row, 2, source_parent)  # Named è in posizione 2
            named_value = model.data(index)
            if self.search_named == "Yes" and not named_value:
                return False
            if self.search_named == "No" and named_value:
                return False
        if self.search_directory != "*":
            index = model.index(source_row, 3, source_parent)  # Directory è in posizione 3
            if model.data(index) != self.search_directory:
                return False
        if self.search_file != "*":
            index = model.index(source_row, 4, source_parent)  # Filename è in posizione 4
            if model.data(index) != self.search_file:
                return False
        
        pattern = self.filterRegExp()
        if pattern.isEmpty():
            return True
        
        # Only search in the Name column (index 1) instead of all columns
        index = model.index(source_row, 1, source_parent)  # Name column
        data = model.data(index)
        if data is not None:
            data_str = str(data)
            search_text = pattern.pattern()
            
            # Usa direttamente self.search_mode invece di cercare di ottenere il valore dal widget
            if self.search_mode == "*":
                return pattern.indexIn(data_str) != -1
            elif self.search_mode == "^":
                return data_str.startswith(search_text)
            elif self.search_mode == "$":
                return data_str.endswith(search_text)
        
        return False

class TableView(QtWidgets.QTableView):
    """Custom QTableView to catch CTRL+C events for copying cell content."""
    def __init__(self, parent=None):
        super(TableView, self).__init__(parent)
        self.setContextMenuPolicy(QtCore.Qt.CustomContextMenu)
        self.customContextMenuRequested.connect(self.show_context_menu)
    
    def eventFilter(self, source, event):
        if event.type() == QtCore.QEvent.KeyPress:
            if event.key() == QtCore.Qt.Key_C and event.modifiers() & QtCore.Qt.ControlModifier:
                indexes = self.selectionModel().selectedIndexes()
                if indexes:
                    text = indexes[0].data()
                    QtWidgets.QApplication.clipboard().setText(text)
                    logging.info(f"Copied to clipboard: {text}")
                    return True
        return super(TableView, self).eventFilter(source, event)
        
    def show_context_menu(self, position):
        indexes = self.selectedIndexes()
        if not indexes:
            return
            
        menu = QtWidgets.QMenu()
        dump_action = menu.addAction("Dump recursive definitions")
        goto_action = menu.addAction("Go to definition")
        copy_declaration_action = menu.addAction("Copy declaration")  # Nuova azione
        
        action = menu.exec_(self.viewport().mapToGlobal(position))
        
        # Get the parent window to access its methods
        parent_window = self.parent()
        while parent_window and not isinstance(parent_window, MainWindow):
            parent_window = parent_window.parent()
        
        if not parent_window:
            return
            
        if action == dump_action:
            parent_window.dump_recursive_definitions(indexes[0])
        elif action == goto_action:
            # Use the same functionality as double-clicking on the file columns
            parent_window.open_file(indexes[0])
        elif action == copy_declaration_action:
            # Nuova funzionalità per copiare la dichiarazione
            parent_window.copy_declaration(indexes[0])

class MainWindow(QtWidgets.QMainWindow):
        
    def __init__(self, records, file_list):
        super(MainWindow, self).__init__()
        self.file_list = file_list
        self.setWindowTitle("C Identifier Explorer")
        self.resize(1200, 600)
        
        central_widget = QtWidgets.QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QtWidgets.QVBoxLayout(central_widget)
        
        # Shortcuts: CTRL+Q to quit, CTRL+R to reload the table.
        exit_shortcut = QtWidgets.QShortcut(QtGui.QKeySequence("Ctrl+Q"), self)
        exit_shortcut.activated.connect(QtWidgets.qApp.quit)
        reload_shortcut = QtWidgets.QShortcut(QtGui.QKeySequence("Ctrl+R"), self)
        reload_shortcut.activated.connect(self.reload_table)
        
        # Create a horizontal layout for search filters.
        search_layout = QtWidgets.QHBoxLayout()
        
      
        # Add a menu button for actions - using hamburger menu icon (≡) and fixed width
        self.action_menu_button = QtWidgets.QPushButton("≡")  # Unicode character for "identical to" (hamburger menu)
        # Set a fixed width to make it square and compact
        self.action_menu_button.setMaximumWidth(30)
        self.action_menu_button.setToolTip("Actions Menu")
        # Optional: Set a stylesheet to make it look better
        self.action_menu_button.setStyleSheet("""
            QPushButton {
                font-size: 16px;
                padding: 2px;
                text-align: center;
            }
        """)
        self.action_menu = QtWidgets.QMenu()
        self.export_all_action = self.action_menu.addAction("Export All")
        self.export_all_action.triggered.connect(self.export_all_definitions)
        self.show_stats_action = self.action_menu.addAction("Show Statistics")
        self.show_stats_action.triggered.connect(self.show_statistics)

        # Nel metodo __init__ della classe MainWindow, dopo la creazione del menu hamburger
        self.export_csv_action = self.action_menu.addAction("Export to CSV")
        self.export_csv_action.triggered.connect(self.export_to_csv)
        
        # Aggiungi un separatore e l'azione Chiudi
        self.action_menu.addSeparator()
        self.exit_action = self.action_menu.addAction("Quit")
        self.exit_action.triggered.connect(QtWidgets.qApp.quit)

        # Mostra il menu quando il pulsante viene cliccato
        self.action_menu_button.clicked.connect(lambda: self.action_menu.exec_(self.action_menu_button.mapToGlobal(QtCore.QPoint(0, self.action_menu_button.height()))))        

        # Aggiungi il pulsante al layout
        search_layout.addWidget(self.action_menu_button)
        
        self.search_type_combo = QtWidgets.QComboBox()
        unique_types = sorted(set(rec["Type"] for rec in records))
        self.search_type_combo.addItem("*")
        for typ in unique_types:
            self.search_type_combo.addItem(typ)

        self.search_type_combo.setCurrentText("*")
        search_layout.addWidget(self.search_type_combo)
        
        self.search_text = QtWidgets.QLineEdit()
        self.search_text.setPlaceholderText("Search by name...")
        # Aggiungi il menu a tendina per la modalità di ricerca
        self.search_mode_combo = QtWidgets.QComboBox()
        self.search_mode_combo.addItem("*")    # Contains
        self.search_mode_combo.addItem("^")    # Starts with (solo il simbolo ^ senza *)
        self.search_mode_combo.addItem("$")    # Ends with (solo il simbolo $ senza *)
        self.search_mode_combo.setToolTip("Search mode: contains (*), starts with (^), ends with ($)")
        self.search_mode_combo.setMaximumWidth(40)
        self.search_mode_combo.setMinimumWidth(40)

        # Aggiungi prima il campo di ricerca, poi la modalità
        search_layout.addWidget(self.search_text)
        search_layout.addWidget(self.search_mode_combo)
        
        self.search_named_combo = QtWidgets.QComboBox()
        self.search_named_combo.addItem("*")
        self.search_named_combo.addItem("Yes")  # Per elementi con nome esplicito
        self.search_named_combo.addItem("No")   # Per elementi senza nome esplicito
        self.search_named_combo.setCurrentText("*")
        search_layout.addWidget(self.search_named_combo)
        
        self.search_directory_combo = QtWidgets.QComboBox()
        unique_dirs = sorted(set(os.path.dirname(rec["File"]) for rec in records if rec.get("File")))
        self.search_directory_combo.addItem("*")
        for d in unique_dirs:
            self.search_directory_combo.addItem(d)
        self.search_directory_combo.setCurrentText("*")
        search_layout.addWidget(self.search_directory_combo)
        
        self.search_file_combo = QtWidgets.QComboBox()
        unique_files = sorted(set(os.path.basename(rec["File"]) for rec in records if rec.get("File")))
        self.search_file_combo.addItem("*")
        for f in unique_files:
            self.search_file_combo.addItem(f)
        self.search_file_combo.setCurrentText("*")
        search_layout.addWidget(self.search_file_combo)
        main_layout.addLayout(search_layout)
        
        # Crea la vista tabella
        self.table_view = TableView(self)
        self.table_view.setSelectionBehavior(QtWidgets.QAbstractItemView.SelectRows)
        self.table_view.setSelectionMode(QtWidgets.QAbstractItemView.SingleSelection)
        self.table_view.installEventFilter(self.table_view)
        main_layout.addWidget(self.table_view)
        
        # Popola la vista tabella con i dati    
        self.model = QtGui.QStandardItemModel()
        # Aggiunta della colonna "Declaration" dopo "Details"
        headers = ["Type", "Name", "Named", "Directory", "Filename", "Line", "Column", "Details", "Declaration"]
        self.model.setHorizontalHeaderLabels(headers)
        
        for rec in records:
            row = []
            # Colonna Type
            type_item = QtGui.QStandardItem(str(rec.get("Type", "")))
            type_item.setFlags(QtCore.Qt.ItemIsSelectable | QtCore.Qt.ItemIsEnabled)
            row.append(type_item)

            # Colonna Name
            name_item = QtGui.QStandardItem(str(rec.get("Name", "")))
            name_item.setFlags(QtCore.Qt.ItemIsSelectable | QtCore.Qt.ItemIsEnabled)
            row.append(name_item)
            
            # Nuova colonna Named (booleana)
            name = rec.get("Name", "")
            is_anonymous = rec.get("IsAnonymous", False)

            has_explicit_name = bool(name and 
                                    not name.startswith("_") and 
                                    not name.startswith("__") and 
                                    not is_anonymous and
                                    "unnamed at" not in name)

            named_item = QtGui.QStandardItem()
            named_item.setData(has_explicit_name, QtCore.Qt.DisplayRole)
            named_item.setFlags(QtCore.Qt.ItemIsSelectable | QtCore.Qt.ItemIsEnabled)
            row.append(named_item)
            
            # Colonne rimanenti
            full_path = rec.get("File", "")
            directory = os.path.dirname(full_path)
            filename = os.path.basename(full_path)
            dir_item = QtGui.QStandardItem(directory)
            dir_item.setFlags(QtCore.Qt.ItemIsSelectable | QtCore.Qt.ItemIsEnabled)
            row.append(dir_item)
            file_item = QtGui.QStandardItem(filename)
            file_item.setFlags(QtCore.Qt.ItemIsSelectable | QtCore.Qt.ItemIsEnabled)
            row.append(file_item)
            row.append(QtGui.QStandardItem(str(rec.get("Line", ""))))
            row.append(QtGui.QStandardItem(str(rec.get("Column", ""))))
            row.append(QtGui.QStandardItem(str(rec.get("Details", ""))))
            
            # Nuova colonna Declaration
            declaration_item = QtGui.QStandardItem(str(rec.get("Declaration", "")))
            declaration_item.setFlags(QtCore.Qt.ItemIsSelectable | QtCore.Qt.ItemIsEnabled)
            row.append(declaration_item)
            
            self.model.appendRow(row)
            logging.debug(f"Row added to model: {[item.text() for item in row]}")
        
        self.proxy_model = CustomFilterProxy()
        self.proxy_model.setSourceModel(self.model)
        self.proxy_model.setFilterCaseSensitivity(QtCore.Qt.CaseInsensitive)
        self.table_view.setModel(self.proxy_model)
        
        # Applica il delegato per la colonna "Named" (indice 2)
        checkbox_delegate = ReadOnlyCheckBoxDelegate(self.table_view)
        self.table_view.setItemDelegateForColumn(2, checkbox_delegate)
        
        self.table_view.setSortingEnabled(True)
        self.table_view.resizeColumnsToContents()
        
        # Imposta una larghezza fissa per la colonna Declaration (indice 8)
        # Imposta una larghezza fissa per la colonna Declaration (indice 8)
        declaration_column_width = 200  # Larghezza in pixel
        self.table_view.setColumnWidth(8, declaration_column_width)

        # Crea l'etichetta di stato per mostrare il numero di elementi visualizzati
        self.status_label = QtWidgets.QLabel("0 items displayed")
        main_layout.addWidget(self.status_label)

        # Collega i filtri all'aggiornamento del conteggio
        self.search_text.textChanged.connect(self.update_text_filter)
        self.search_type_combo.currentTextChanged.connect(self.update_type_filter)
        self.search_directory_combo.currentTextChanged.connect(self.update_directory_filter)
        self.search_file_combo.currentTextChanged.connect(self.update_file_filter)
        self.search_named_combo.currentTextChanged.connect(self.update_named_filter)
        self.search_mode_combo.currentTextChanged.connect(self.update_search_mode)

        # Aggiorna il conteggio iniziale
        self.update_item_count()

        self.table_view.clicked.connect(self.handle_table_click)
        self.table_view.doubleClicked.connect(self.handle_table_double_click)

    def update_text_filter(self, text):
        """Aggiorna il filtro di testo quando l'utente digita nel campo di ricerca."""
        self.proxy_model.setFilterRegExp(text)
        self.update_item_count()
        
    def update_type_filter(self, type_text):
        """Aggiorna il filtro per tipo."""
        self.proxy_model.setSearchType(type_text)
        self.update_item_count()
        
    def update_directory_filter(self, directory):
        """Aggiorna il filtro per directory."""
        self.proxy_model.setSearchDirectory(directory)
        self.update_item_count()
        
    def update_file_filter(self, file_name):
        """Aggiorna il filtro per file."""
        self.proxy_model.setSearchFile(file_name)
        self.update_item_count()
        
    def update_named_filter(self, named_value):
        """Aggiorna il filtro per elementi con nome."""
        self.proxy_model.setSearchNamed(named_value)
        self.update_item_count()
        
    def update_search_mode(self, mode):
        """Aggiorna la modalità di ricerca."""
        self.proxy_model.setSearchMode(mode)
        # Riapplica il filtro di testo con la nuova modalità
        self.proxy_model.setFilterRegExp(self.search_text.text())
        self.update_item_count()

    def get_export_options(self, title="Export Options"):
        """
        Mostra una finestra di dialogo con le opzioni di esportazione e restituisce le scelte dell'utente.
        """
        options_dialog = QtWidgets.QDialog(self)
        options_dialog.setWindowTitle(title)
        options_dialog.setMinimumWidth(400)
        
        dialog_layout = QtWidgets.QVBoxLayout(options_dialog)
        
        # Checkbox per applicare il filtro di ricerca corrente
        apply_search_filter_checkbox = QtWidgets.QCheckBox("Apply current search filter (export only items matching the current search)")
        apply_search_filter_checkbox.setChecked(False)  # Default: esporta tutto
        dialog_layout.addWidget(apply_search_filter_checkbox)
        
        # Checkbox per escludere oggetti che potrebbero causare duplicazioni
        exclude_duplicating_objects_checkbox = QtWidgets.QCheckBox("Exclude prone-duplicating information objects (e.g., prefer typedefs over struct definitions)")
        exclude_duplicating_objects_checkbox.setChecked(True)  # Default: esclude oggetti che potrebbero causare duplicazioni
        dialog_layout.addWidget(exclude_duplicating_objects_checkbox)
        
        exclude_unnamed_checkbox = QtWidgets.QCheckBox("Exclude unnamed elements (only export elements with explicit names)")
        exclude_unnamed_checkbox.setChecked(True)
        dialog_layout.addWidget(exclude_unnamed_checkbox)
        
        button_box = QtWidgets.QDialogButtonBox(
            QtWidgets.QDialogButtonBox.Ok | QtWidgets.QDialogButtonBox.Cancel
        )
        button_box.accepted.connect(options_dialog.accept)
        button_box.rejected.connect(options_dialog.reject)
        dialog_layout.addWidget(button_box)
        
        result = options_dialog.exec_()
        
        if result == QtWidgets.QDialog.Accepted:
            return (True, 
                    apply_search_filter_checkbox.isChecked(),
                    exclude_duplicating_objects_checkbox.isChecked(),  # True significa escludere, False significa includere tutto
                    exclude_unnamed_checkbox.isChecked())
        else:
            return (False, False, True, False)  # L'utente ha annullato, manteniamo i valori di default
            
    def export_to_csv(self):
        """Esporta il contenuto della tabella in un file CSV."""
        logging.info("Exporting table to CSV...")
        
        # Chiedi all'utente dove salvare il file CSV
        file_name, _ = QtWidgets.QFileDialog.getSaveFileName(
            self, 
            "Save Table as CSV", 
            "table_export.csv",
            "CSV Files (*.csv);;Text Files (*.txt);;All Files (*)"
        )
        
        if not file_name:
            return  # L'utente ha annullato
        
        try:
            with open(file_name, 'w', newline='') as csvfile:
                # Crea un writer CSV
                import csv
                writer = csv.writer(csvfile)
                
                # Scrivi l'intestazione
                headers = []
                for col in range(self.model.columnCount()):
                    headers.append(self.model.headerData(col, QtCore.Qt.Horizontal))
                writer.writerow(headers)
                
                # Ottieni le opzioni di esportazione
                accepted, export_filtered_only, exclude_unnamed = self.get_export_options("CSV Export Options")
                
                if not accepted:
                    return  # L'utente ha annullato
                
                # Conta quante righe saranno esportate per la barra di progresso
                if export_filtered_only:
                    total_rows = self.proxy_model.rowCount()
                    if exclude_unnamed:
                        # Conta solo le righe con Named = True
                        named_count = 0
                        for row in range(total_rows):
                            index = self.proxy_model.index(row, 2)  # Colonna "Named"
                            if self.proxy_model.data(index):
                                named_count += 1
                        total_rows = named_count
                else:
                    total_rows = self.model.rowCount()
                    if exclude_unnamed:
                        # Conta solo le righe con Named = True
                        named_count = 0
                        for row in range(total_rows):
                            index = self.model.index(row, 2)  # Colonna "Named"
                            if self.model.data(index):
                                named_count += 1
                        total_rows = named_count
                
                # Mostra una finestra di progresso
                progress = QtWidgets.QProgressDialog("Exporting to CSV...", "Cancel", 0, total_rows, self)
                progress.setWindowModality(QtCore.Qt.WindowModal)
                progress.setMinimumDuration(0)
                progress.setValue(0)
                
                # Contatore per le righe effettivamente esportate
                exported_rows = 0
                
                # Scrivi i dati
                if export_filtered_only:
                    # Esporta solo le righe filtrate/visibili
                    for row in range(self.proxy_model.rowCount()):
                        # Verifica se l'elemento ha un nome esplicito (se richiesto)
                        if exclude_unnamed:
                            named_index = self.proxy_model.index(row, 2)  # Colonna "Named"
                            if not self.proxy_model.data(named_index):
                                continue  # Salta questo elemento
                        
                        if progress.wasCanceled():
                            break
                        
                        progress.setValue(exported_rows)
                        QtWidgets.QApplication.processEvents()
                        
                        row_data = []
                        for col in range(self.proxy_model.columnCount()):
                            index = self.proxy_model.index(row, col)
                            # Per la colonna "Named" (booleana), converti in "Yes"/"No"
                            if col == 2:  # Colonna "Named"
                                value = self.proxy_model.data(index)
                                row_data.append("Yes" if value else "No")
                            else:
                                row_data.append(self.proxy_model.data(index))
                        writer.writerow(row_data)
                        exported_rows += 1
                else:
                    # Esporta tutte le righe
                    for row in range(self.model.rowCount()):
                        # Verifica se l'elemento ha un nome esplicito (se richiesto)
                        if exclude_unnamed:
                            named_index = self.model.index(row, 2)  # Colonna "Named"
                            if not self.model.data(named_index):
                                continue  # Salta questo elemento
                        
                        if progress.wasCanceled():
                            break
                        
                        progress.setValue(exported_rows)
                        QtWidgets.QApplication.processEvents()
                        
                        row_data = []
                        for col in range(self.model.columnCount()):
                            index = self.model.index(row, col)
                            # Per la colonna "Named" (booleana), converti in "Yes"/"No"
                            if col == 2:  # Colonna "Named"
                                value = self.model.data(index)
                                row_data.append("Yes" if value else "No")
                            else:
                                row_data.append(self.model.data(index))
                        writer.writerow(row_data)
                        exported_rows += 1
                
                progress.setValue(total_rows)
                
            logging.info(f"Table exported to CSV: {file_name} ({exported_rows} rows)")
            QtWidgets.QMessageBox.information(
                self, 
                "Success", 
                f"Table successfully exported to {file_name}\n{exported_rows} rows exported."
            )
        except Exception as e:
            logging.error(f"Error exporting table to CSV: {e}")
            QtWidgets.QMessageBox.critical(
                self, 
                "Error", 
                f"Could not export table to CSV: {e}"
            )

    def handle_table_click(self, index):
        logging.debug(f"Table clicked at row {index.row()}, column {index.column()}")
        # For Type, update now only on double-click; here do nothing.
        if index.column() == 1:
            source_index = self.proxy_model.mapToSource(index)
            name_value = self.model.item(source_index.row(), 1).text()
            QtWidgets.QApplication.clipboard().setText(name_value)
            logging.info(f"Copied Name to clipboard: {name_value}")
        elif index.column() in [5, 6, 7]:  # Aggiornati gli indici per Line, Column, Details
            self.open_file(index)
        # For Directory (3) and Filename (4), single click does nothing.
    
    def handle_table_double_click(self, index):
        logging.debug(f"Table double-clicked at row {index.row()}, column {index.column()}")
        if index.column() == 0:
            source_index = self.proxy_model.mapToSource(index)
            type_value = self.model.item(source_index.row(), 0).text()
            self.search_type_combo.setCurrentText(type_value)
            self.proxy_model.setSearchType(type_value)
            logging.info(f"Updated search type to {type_value}")
        elif index.column() == 1:
            source_index = self.proxy_model.mapToSource(index)
            name_value = self.model.item(source_index.row(), 1).text()
            QtWidgets.QApplication.clipboard().setText(name_value)
            logging.info(f"Copied Name to clipboard: {name_value}")
        elif index.column() == 3:  # Directory è ora in posizione 3
            self.open_directory(index)
        elif index.column() in [4, 5, 6, 7]:  # Aggiornati gli indici per Filename, Line, Column, Details
            self.open_file(index)
    
    def open_file(self, index):
        source_index = self.proxy_model.mapToSource(index)
        row = source_index.row()
        dir_item = self.model.item(row, 3)  # Directory è ora in posizione 3
        file_item = self.model.item(row, 4)  # Filename è ora in posizione 4
        line_item = self.model.item(row, 5)  # Line è ora in posizione 5
        directory = dir_item.text()
        filename = file_item.text()
        file_path = os.path.join(directory, filename)
        line_number = line_item.text()
        logging.info(f"Attempting to open file: {file_path} at line: {line_number}")
        if file_path and line_number:
            try:
                command = ["gedit", f"+{line_number}", file_path]
                subprocess.Popen(command)
                logging.info(f"Opened file with command: {' '.join(command)}")
            except Exception as e:
                logging.error(f"Error opening file: {e}")
                QtWidgets.QMessageBox.warning(self, "Error", f"Unable to open file with gedit:\n{e}")
    
    def open_directory(self, index):
        source_index = self.proxy_model.mapToSource(index)
        row = source_index.row()
        dir_item = self.model.item(row, 3)  # Directory è ora in posizione 3
        directory = dir_item.text()
        logging.info(f"Attempting to open directory: {directory}")
        if directory:
            try:
                command = [BROWSER_COMMAND, directory]
                subprocess.Popen(command)
                logging.info(f"Opened directory with command: {' '.join(command)}")
            except Exception as e:
                logging.error(f"Error opening directory: {e}")
                QtWidgets.QMessageBox.warning(self, "Error", f"Unable to open directory with {BROWSER_COMMAND}:\n{e}")
    def copy_declaration(self, index):
        """Copia la dichiarazione dell'elemento selezionato negli appunti."""
        source_index = self.proxy_model.mapToSource(index)
        row = source_index.row()
        
        # Ottieni la dichiarazione dalla colonna Declaration (indice 8)
        declaration_item = self.model.item(row, 8)
        
        if declaration_item and declaration_item.text():
            declaration = declaration_item.text()
            QtWidgets.QApplication.clipboard().setText(declaration)
            logging.info(f"Copied declaration to clipboard: {declaration}")
            
            # Mostra un messaggio di conferma temporaneo (tooltip)
            QtWidgets.QToolTip.showText(
                QtGui.QCursor.pos(),
                "Declaration copied to clipboard",
                self.table_view,
                QtCore.QRect(),
                2000  # Mostra per 2 secondi
            )
        else:
            # Se la dichiarazione non è disponibile, mostra un messaggio
            QtWidgets.QMessageBox.information(
                self,
                "Information",
                "No declaration available for this item."
            )

    def reload_table(self):
        logging.info("Reloading table from scratch...")
        records = process_files(self.file_list)
        self.model.clear()
        # Aggiornati gli header per includere "Named" e "Declaration"
        headers = ["Type", "Name", "Named", "Directory", "Filename", "Line", "Column", "Details", "Declaration"]
        self.model.setHorizontalHeaderLabels(headers)
        for rec in records:
            row = []
            # Colonna Type
            type_item = QtGui.QStandardItem(str(rec.get("Type", "")))
            type_item.setFlags(QtCore.Qt.ItemIsSelectable | QtCore.Qt.ItemIsEnabled)
            row.append(type_item)
            
            # Colonna Name
            name_item = QtGui.QStandardItem(str(rec.get("Name", "")))
            name_item.setFlags(QtCore.Qt.ItemIsSelectable | QtCore.Qt.ItemIsEnabled)
            row.append(name_item)
            
            # Nuova colonna Named (booleana)
            name = rec.get("Name", "")
            is_anonymous = rec.get("IsAnonymous", False)

            # Un elemento ha un nome esplicito se:
            # 1. Non è anonimo (ha un nome)
            # 2. Il nome non inizia con underscore singolo o doppio
            # 3. Il nome non contiene "unnamed at" (per le strutture anonime)
            has_explicit_name = bool(name and 
                                    not name.startswith("_") and 
                                    not name.startswith("__") and 
                                    not is_anonymous and
                                    "unnamed at" not in name)

            named_item = QtGui.QStandardItem()
            named_item.setData(has_explicit_name, QtCore.Qt.DisplayRole)
            named_item.setFlags(QtCore.Qt.ItemIsSelectable | QtCore.Qt.ItemIsEnabled)
            row.append(named_item)
            
            # Colonne rimanenti
            full_path = rec.get("File", "")
            directory = os.path.dirname(full_path)
            filename = os.path.basename(full_path)
            dir_item = QtGui.QStandardItem(directory)
            dir_item.setFlags(QtCore.Qt.ItemIsSelectable | QtCore.Qt.ItemIsEnabled)
            row.append(dir_item)
            file_item = QtGui.QStandardItem(filename)
            file_item.setFlags(QtCore.Qt.ItemIsSelectable | QtCore.Qt.ItemIsEnabled)
            row.append(file_item)
            row.append(QtGui.QStandardItem(str(rec.get("Line", ""))))
            row.append(QtGui.QStandardItem(str(rec.get("Column", ""))))
            row.append(QtGui.QStandardItem(str(rec.get("Details", ""))))
            
            # Nuova colonna Declaration
            declaration_item = QtGui.QStandardItem(str(rec.get("Declaration", "")))
            declaration_item.setFlags(QtCore.Qt.ItemIsSelectable | QtCore.Qt.ItemIsEnabled)
            row.append(declaration_item)
            
            self.model.appendRow(row)
            logging.debug(f"Row reloaded: {[item.text() for item in row]}")

        
        # Riapplica il delegato per la colonna "Named"
        checkbox_delegate = ReadOnlyCheckBoxDelegate(self.table_view)
        self.table_view.setItemDelegateForColumn(2, checkbox_delegate)
        
        self.table_view.resizeColumnsToContents()

        # Imposta una larghezza fissa per la colonna Declaration (indice 8)
        declaration_column_width = 200  # Larghezza in pixel
        self.table_view.setColumnWidth(8, declaration_column_width)
        
        # Rebuild search filter combo boxes.
        self.search_type_combo.blockSignals(True)
        self.search_directory_combo.blockSignals(True)
        self.search_file_combo.blockSignals(True)
        self.search_named_combo.blockSignals(True) 
        self.search_type_combo.clear()
        self.search_directory_combo.clear()
        self.search_file_combo.clear()
        self.search_type_combo.addItem("*")
        self.search_directory_combo.addItem("*")
        self.search_file_combo.addItem("*")
        unique_types = sorted(set(rec["Type"] for rec in records))
        for typ in unique_types:
            self.search_type_combo.addItem(typ)
        unique_dirs = sorted(set(os.path.dirname(rec["File"]) for rec in records if rec.get("File")))
        for d in unique_dirs:
            self.search_directory_combo.addItem(d)
        unique_files = sorted(set(os.path.basename(rec["File"]) for rec in records if rec.get("File")))
        for f in unique_files:
            self.search_file_combo.addItem(f)
        self.search_type_combo.blockSignals(False)
        self.search_directory_combo.blockSignals(False)
        self.search_file_combo.blockSignals(False)
        self.search_named_combo.blockSignals(False)
        
        # Riapplica i filtri correnti
        # Importante: prima riapplica i filtri, poi invalida il modello proxy
        search_text = self.search_text.text()
        search_type = self.search_type_combo.currentText()
        search_directory = self.search_directory_combo.currentText()
        search_file = self.search_file_combo.currentText()
        search_named = self.search_named_combo.currentText()
        search_mode = self.search_mode_combo.currentText()
        
        # Imposta i filtri nel proxy model
        self.proxy_model.setSearchType(search_type)
        self.proxy_model.setSearchDirectory(search_directory)
        self.proxy_model.setSearchFile(search_file)
        self.proxy_model.setSearchNamed(search_named)
        self.proxy_model.setSearchMode(search_mode)
        
        # Imposta il filtro di testo
        self.proxy_model.setFilterRegExp(search_text)
        
        # Ora invalida il modello proxy per applicare tutti i filtri
        self.proxy_model.invalidate()
        
        # Aggiorna il conteggio degli elementi visualizzati
        self.update_item_count()
        
        logging.info("Reload complete.")

    def update_item_count(self):
        """Aggiorna l'etichetta di stato con il numero di elementi visualizzati."""
        count = self.proxy_model.rowCount()
        total = self.model.rowCount()
        self.status_label.setText(f"{count} of {total} items displayed")    

    def dump_recursive_definitions(self, index):
        """Extract and display the complete C definition of the selected item and all its dependencies."""
        source_index = self.proxy_model.mapToSource(index)
        row = source_index.row()
        
        # Get information about the selected item
        type_item = self.model.item(row, 0)
        name_item = self.model.item(row, 1)
        dir_item = self.model.item(row, 3)  # Directory è ora in posizione 3
        file_item = self.model.item(row, 4)  # Filename è ora in posizione 4
        details_item = self.model.item(row, 7)  # Details è ora in posizione 7
        
        item_type = type_item.text()
        item_name = name_item.text()
        directory = dir_item.text()
        filename = file_item.text()
        details = details_item.text() if details_item else ""
        file_path = os.path.join(directory, filename)
        
        logging.info(f"Dumping recursive definitions for {item_type} {item_name} in {file_path}")
        
        # For VAR_DECL, extract the type from the details
        if item_type == "VAR_DECL":
            # The details column contains the type information
            var_type = details.split(" (const)")[0] if " (const)" in details else details
            logging.info(f"Variable type: {var_type}")
            
            # Extract the definitions for the variable's type
            definitions = self.extract_recursive_definitions(file_path, "TYPE", var_type)
            
            if not definitions:
                # Try to get just the variable declaration
                definitions = self.extract_variable_declaration(file_path, item_name)
                
            if not definitions:
                QtWidgets.QMessageBox.warning(
                    self, 
                    "Warning", 
                    f"Could not extract type definition for variable {item_name} of type {var_type}."
                )
                return
            
            # Display the definitions in a popup window
            self.show_definitions_popup(definitions, f"Variable {item_name} of type {var_type}")
            return
        
        # For other types that can have recursive definitions
        elif item_type not in ["STRUCT_DECL", "TYPEDEF_DECL", "ENUM_DECL", "UNION_DECL"]:
            QtWidgets.QMessageBox.information(
                self, 
                "Information", 
                f"Recursive definition dump is only available for struct, typedef, enum, union declarations, and variables."
            )
            return
        
        # Extract the definitions
        definitions = self.extract_recursive_definitions(file_path, item_type, item_name)
        
        if not definitions:
            QtWidgets.QMessageBox.warning(
                self, 
                "Warning", 
                f"Could not extract definitions for {item_type} {item_name}."
            )
            return
        
        # Display the definitions in a popup window
        self.show_definitions_popup(definitions, f"{item_type} {item_name}")

    def extract_variable_declaration(self, file_path, var_name):
        """Extract the declaration of a variable from the file."""
        try:
            # Create a temporary file to store the preprocessed source
            with tempfile.NamedTemporaryFile(suffix='.c', delete=False) as temp_file:
                temp_path = temp_file.name
            
            # Preprocess the file to expand all includes and macros
            preprocess_cmd = ["gcc", "-E", "-P", file_path, "-o", temp_path]
            subprocess.run(preprocess_cmd, check=True)
            
            # Read the preprocessed file
            with open(temp_path, 'r') as f:
                preprocessed_source = f.read()
            
            # Look for the variable declaration
            import re
            # Pattern to match variable declarations like "int var_name;" or "const char* var_name = ..."
            var_pattern = f"(const\\s+)?[a-zA-Z0-9_]+\\s+[\\*\\s]*{var_name}\\s*[=;][^;]*;"
            match = re.search(var_pattern, preprocessed_source)
            
            if match:
                return match.group(0)
            return None
        
        except Exception as e:
            logging.error(f"Error extracting variable declaration: {e}")
            return None
        finally:
            # Clean up the temporary file
            if os.path.exists(temp_path):
                os.unlink(temp_path)
    def extract_recursive_definitions(self, file_path, item_type, item_name):
            """
            Extract the complete C definition of the item and all its dependencies.
            Returns a string containing all the definitions in the correct order.
            """
            # Create a temporary file to store the preprocessed source
            with tempfile.NamedTemporaryFile(suffix='.c', delete=False) as temp_file:
                temp_path = temp_file.name
            
            try:
                # Preprocess the file to expand all includes and macros
                preprocess_cmd = ["gcc", "-E", "-P", file_path, "-o", temp_path]
                subprocess.run(preprocess_cmd, check=True)
                
                # Parse the preprocessed file with clang
                index = clang.cindex.Index.create()
                tu = index.parse(temp_path, args=['-std=c99'])
                
                # Find the target declaration
                target_cursor = None
                dependency_cursors = []
                
                def find_declaration(cursor, parent=None):
                    nonlocal target_cursor
                    
                    if (cursor.kind.name == item_type and 
                        cursor.spelling == item_name and 
                        cursor.location.file and 
                        os.path.normpath(cursor.location.file.name) == os.path.normpath(file_path)):
                        target_cursor = cursor
                        return True
                    
                    for child in cursor.get_children():
                        if find_declaration(child, cursor):
                            return True
                    return False
                
                find_declaration(tu.cursor)
                
                if not target_cursor:
                    logging.error(f"Could not find declaration for {item_type} {item_name} in {file_path}")
                    return None
                
                # Collect all dependencies
                collected_types = set()
                dependency_definitions = []
                
                def collect_dependencies(cursor, collected):
                    if not cursor:
                        return
                        
                    # For typedefs, get the underlying type
                    if cursor.kind == clang.cindex.CursorKind.TYPEDEF_DECL:
                        underlying_type = cursor.underlying_typedef_type
                        if underlying_type.kind == clang.cindex.TypeKind.ELABORATED:
                            # Get the declaration for this type
                            type_decl = underlying_type.get_declaration()
                            if type_decl and type_decl.spelling not in collected:
                                collected.add(type_decl.spelling)
                                collect_dependencies(type_decl, collected)
                    
                    # For structs and unions, collect field types
                    elif cursor.kind in [clang.cindex.CursorKind.STRUCT_DECL, clang.cindex.CursorKind.UNION_DECL]:
                        for field in cursor.get_children():
                            if field.kind == clang.cindex.CursorKind.FIELD_DECL:
                                field_type = field.type
                                if field_type.kind == clang.cindex.TypeKind.ELABORATED:
                                    type_decl = field_type.get_declaration()
                                    if type_decl and type_decl.spelling not in collected:
                                        collected.add(type_decl.spelling)
                                        collect_dependencies(type_decl, collected)
                
                # Start collecting dependencies from the target cursor
                collect_dependencies(target_cursor, collected_types)
                
                # Extract the source code for the target and its dependencies
                with open(temp_path, 'r') as f:
                    preprocessed_source = f.read()
                
                # Extract the definitions in the correct order
                definitions = []
                
                # First, extract all dependency definitions
                for type_name in collected_types:
                    # Find the definition in the preprocessed source
                    # This is a simplified approach and might need refinement
                    type_pattern = f"(typedef|struct|union|enum)\\s+{type_name}\\s*\\{{[^}}]*\\}}\\s*;"
                    import re
                    match = re.search(type_pattern, preprocessed_source)
                    if match:
                        definitions.append(match.group(0))
                
                # Then, extract the target definition
                target_pattern = None
                if item_type == "STRUCT_DECL":
                    target_pattern = f"struct\\s+{item_name}\\s*\\{{[^}}]*\\}}\\s*;"
                elif item_type == "TYPEDEF_DECL":
                    target_pattern = f"typedef\\s+.*\\s+{item_name}\\s*;"
                elif item_type == "ENUM_DECL":
                    target_pattern = f"enum\\s+{item_name}\\s*\\{{[^}}]*\\}}\\s*;"
                elif item_type == "UNION_DECL":
                    target_pattern = f"union\\s+{item_name}\\s*\\{{[^}}]*\\}}\\s*;"
                
                if target_pattern:
                    match = re.search(target_pattern, preprocessed_source)
                    if match:
                        definitions.append(match.group(0))
                
                return "\n\n".join(definitions)
            
            except Exception as e:
                logging.error(f"Error extracting definitions: {e}")
                return None
            finally:
                # Clean up the temporary file
                if os.path.exists(temp_path):
                    os.unlink(temp_path)

    def show_definitions_popup(self, definitions, title):
        """Display the extracted definitions in a popup window."""
        dialog = QtWidgets.QDialog(self)
        dialog.setWindowTitle(f"Recursive Definitions: {title}")
        dialog.resize(800, 600)
        
        layout = QtWidgets.QVBoxLayout(dialog)
        
        # Text area for displaying the definitions
        text_edit = QtWidgets.QTextEdit()
        text_edit.setReadOnly(True)
        text_edit.setFont(QtGui.QFont("Courier New", 10))
        text_edit.setText(definitions)
        layout.addWidget(text_edit)
        
        # Buttons for copying and saving
        button_layout = QtWidgets.QHBoxLayout()
        
        copy_button = QtWidgets.QPushButton("Copy to Clipboard")
        copy_button.clicked.connect(lambda: QtWidgets.QApplication.clipboard().setText(definitions))
        button_layout.addWidget(copy_button)
        
        save_button = QtWidgets.QPushButton("Save to File")
        save_button.clicked.connect(lambda: self.save_definitions_to_file(definitions, title))
        button_layout.addWidget(save_button)
        
        close_button = QtWidgets.QPushButton("Close")
        close_button.clicked.connect(dialog.accept)
        button_layout.addWidget(close_button)
        
        layout.addLayout(button_layout)
        
        dialog.exec_()

    def save_definitions_to_file(self, definitions, title):
        """Save the definitions to a file."""
        file_name, _ = QtWidgets.QFileDialog.getSaveFileName(
            self, 
            "Save Definitions", 
            f"{title.replace(' ', '_')}_definitions.h", 
            "Header Files (*.h);;Text Files (*.txt);;All Files (*)"
        )
        
        if file_name:
            try:
                with open(file_name, 'w') as f:
                    f.write(definitions)
                logging.info(f"Definitions saved to {file_name}")
                QtWidgets.QMessageBox.information(
                    self, 
                    "Success", 
                    f"Definitions successfully saved to {file_name}"
                )
            except Exception as e:
                logging.error(f"Error saving definitions: {e}")
                QtWidgets.QMessageBox.critical(
                    self, 
                    "Error", 
                    f"Could not save definitions: {e}"
                )
    def export_all_definitions(self):
        """Export all struct, typedef, enum, union, macro, variable and function definitions to a single file."""
        logging.info("Exporting all definitions...")
        
        file_name, _ = QtWidgets.QFileDialog.getSaveFileName(
            self, 
            "Save All Definitions", 
            "all_definitions.defs",
            "Header Files (*.defs);;Definition Files (*.defs);;Text Files (*.txt);;All Files (*)"
        )
        
        if not file_name:
            return  # User cancelled
        
        accepted, apply_search_filter, exclude_duplicating_objects, exclude_unnamed = self.get_export_options("Definitions Export Options")
        
        if not accepted:
            return  # L'utente ha annullato
        
        # Add FUNCTION_DECL to the list of target types
        target_types = ["STRUCT_DECL", "TYPEDEF_DECL", "ENUM_DECL", "UNION_DECL", "MACRO_DEFINITION", "VAR_DECL", "FUNCTION_DECL"]
        all_definitions = []
        processed_items = set()  # To avoid duplicates
        typedef_names = set()  # Per tenere traccia dei nomi definiti tramite typedef
        
        # Determina quali righe processare in base alle opzioni
        if apply_search_filter:
            rows_to_process = [self.proxy_model.mapToSource(self.proxy_model.index(row, 0)).row() 
                            for row in range(self.proxy_model.rowCount())]
        else:
            rows_to_process = list(range(self.model.rowCount()))
        
        # Show a progress dialog
        progress = QtWidgets.QProgressDialog("Exporting definitions...", "Cancel", 0, len(rows_to_process), self)
        progress.setWindowModality(QtCore.Qt.WindowModal)
        progress.setMinimumDuration(0)
        progress.setValue(0)
        
        # Primo passaggio: raccogli tutti i nomi definiti tramite typedef
        for row in rows_to_process:
            type_item = self.model.item(row, 0)
            name_item = self.model.item(row, 1)
            item_type = type_item.text()
            item_name = name_item.text()

            if item_type == "TYPEDEF_DECL":
                typedef_names.add(item_name)
        
        # Process selected rows
        for i, row in enumerate(rows_to_process):
            if progress.wasCanceled():
                break
                
            progress.setValue(i)
            QtWidgets.QApplication.processEvents()
            
            type_item = self.model.item(row, 0)
            name_item = self.model.item(row, 1)
            named_value = self.model.item(row, 2).data(QtCore.Qt.DisplayRole)  # Valore booleano Named
            dir_item = self.model.item(row, 3)  # Directory column
            file_item = self.model.item(row, 4)  # Filename column
            line_item = self.model.item(row, 5)  # Line column
            declaration_item = self.model.item(row, 8)  # Declaration column
            
            if not all([type_item, name_item, dir_item, file_item]):
                logging.warning(f"Skipping row {row}: missing item data")
                continue
                
            item_type = type_item.text()
            item_name = name_item.text()
            line_number = line_item.text()
        
            # Skip if not a target type or already processed or has no name
            if item_type not in target_types or (item_type, item_name) in processed_items or not item_name:
                continue
            
            # Skip unnamed elements if requested
            if exclude_unnamed and not named_value:
                continue
            
            directory = dir_item.text()
            filename = file_item.text()
            file_path = os.path.join(directory, filename)
            
            logging.info(f"Processing {item_type} {item_name} from {file_path}")
            
            # Usa la dichiarazione completa dal campo Declaration se disponibile
            declaration = declaration_item.text() if declaration_item and declaration_item.text() else None
            info = f"/* From file: {file_path}:{line_number} Type:{item_type} */"
            
            if item_type == "TYPEDEF_DECL":
                # Includi sempre i typedef
                all_definitions.append(info)
                all_definitions.append(declaration)
                processed_items.add((item_type, item_name))
            elif item_type in ["STRUCT_DECL", "ENUM_DECL", "UNION_DECL"]:
                # Se exclude_duplicating_objects è True, includi solo se non c'è un typedef corrispondente
                if not exclude_duplicating_objects or item_name not in typedef_names:
                    all_definitions.append(info)
                    all_definitions.append(declaration)
                    processed_items.add((item_type, item_name))
            elif item_type in ["MACRO_DEFINITION", "VAR_DECL"]:
                # Includi sempre macro e variabili
                all_definitions.append(info)
                all_definitions.append(declaration)
                processed_items.add((item_type, item_name))
            elif item_type == "FUNCTION_DECL":
                # Includi le dichiarazioni di funzione
                all_definitions.append(info)
                # Per le funzioni, aggiungi un punto e virgola se non è già presente
                if declaration and not declaration.strip().endswith(';'):
                    declaration = declaration.strip() + ';'
                all_definitions.append(declaration)
                processed_items.add((item_type, item_name))
            
            if not declaration:
                # Fallback: genera una dichiarazione di base se il campo Declaration è vuoto
                fallback_declaration = None
                
                if item_type == "STRUCT_DECL":
                    fallback_declaration = f"struct {item_name} {{ /* Definition not available */ }};"
                elif item_type == "TYPEDEF_DECL":
                    fallback_declaration = f"typedef void {item_name}; /* Actual type not available */"
                elif item_type == "ENUM_DECL":
                    fallback_declaration = f"enum {item_name} {{ /* Enum values not available */ }};"
                elif item_type == "UNION_DECL":
                    fallback_declaration = f"union {item_name} {{ /* Union fields not available */ }};"
                elif item_type == "MACRO_DEFINITION":
                    fallback_declaration = f"#define {item_name} /* Macro value not available */"
                elif item_type == "VAR_DECL":
                    fallback_declaration = f"extern int {item_name}; /* Actual type not available */"
                elif item_type == "FUNCTION_DECL":
                    fallback_declaration = f"extern void {item_name}(void); /* Function signature not available */"
                
                if fallback_declaration:
                    all_definitions.append(info)
                    all_definitions.append(fallback_declaration)
                    processed_items.add((item_type, item_name))
                    logging.info(f"Added fallback definition for {item_type} {item_name}")
        
        progress.setValue(len(rows_to_process))
        
        if not all_definitions:
            QtWidgets.QMessageBox.warning(
                self, 
                "Warning", 
                "No definitions were found to export."
            )
            return
        
        # Filtra gli elementi None dalla lista all_definitions
        all_definitions = [d for d in all_definitions if d is not None]

        # Create a header guard based on the file name
        base_name = os.path.basename(file_name)
        header_guard = base_name.replace(".", "_").upper()
        
        # Combine all definitions with header guards
        combined_content = [
            f"#ifndef {header_guard}",
            f"#define {header_guard}",
            "",
            "/* Automatically generated by C Identifier Explorer */",
            "/* Contains all struct, typedef, enum, union, macro, variable and function definitions */",
            "",
            "\n\n".join(all_definitions),
            "",
            f"#endif /* {header_guard} */",
            ""
        ]
        
        # Write to file
        try:
            with open(file_name, 'w') as f:
                f.write("\n".join(combined_content))
            
            logging.info(f"All definitions saved to {file_name}")
            QtWidgets.QMessageBox.information(
                self, 
                "Success", 
                f"Successfully exported {len(processed_items)} definitions to {file_name}"
            )
        except Exception as e:
            logging.error(f"Error saving all definitions: {e}")
            QtWidgets.QMessageBox.critical(
                self, 
                "Error", 
                f"Could not save all definitions: {e}"
            )

    def show_statistics(self):
        """Show statistics about the loaded items in the table."""
        logging.info("Generating statistics...")
        
        # Collect statistics
        total_items = self.model.rowCount()
        
        # Count by type
        type_counts = {}
        for row in range(total_items):
            item_type = self.model.item(row, 0).text()
            type_counts[item_type] = type_counts.get(item_type, 0) + 1
        
        # Count by file extension
        file_ext_counts = {}
        for row in range(total_items):
            # Filename è ora in posizione 4
            filename = self.model.item(row, 4).text()
            ext = os.path.splitext(filename)[1] if filename else "unknown"
            file_ext_counts[ext] = file_ext_counts.get(ext, 0) + 1
        
        # Count by directory
        dir_counts = {}
        for row in range(total_items):
            # Directory è ora in posizione 3
            directory = self.model.item(row, 3).text()
            if directory:
                # Get the last part of the directory path for cleaner display
                dir_counts[directory] = dir_counts.get(directory, 0) + 1
        
        # Create a dialog to display the statistics
        dialog = QtWidgets.QDialog(self)
        dialog.setWindowTitle("Statistics")
        dialog.resize(600, 500)
        
        layout = QtWidgets.QVBoxLayout(dialog)
        
        # Add a tab widget to organize different statistics
        tab_widget = QtWidgets.QTabWidget()
        layout.addWidget(tab_widget)
        
        # Summary tab
        summary_widget = QtWidgets.QWidget()
        summary_layout = QtWidgets.QVBoxLayout(summary_widget)
        
        summary_text = QtWidgets.QTextEdit()
        summary_text.setReadOnly(True)
        summary_text.setFont(QtGui.QFont("Arial", 10))
        
        summary_content = [
            "<h2>Summary Statistics</h2>",
            f"<p><b>Total items:</b> {total_items}</p>",
            f"<p><b>Unique types:</b> {len(type_counts)}</p>",
            f"<p><b>File extensions:</b> {len(file_ext_counts)}</p>",
            f"<p><b>Directories:</b> {len(dir_counts)}</p>",
            "<h3>Top Types</h3>",
            "<ul>"
        ]
        
        # Sort types by count (descending)
        sorted_types = sorted(type_counts.items(), key=lambda x: x[1], reverse=True)
        for type_name, count in sorted_types[:5]:  # Show top 5
            summary_content.append(f"<li><b>{type_name}:</b> {count} ({count/total_items*100:.1f}%)</li>")
        
        summary_content.append("</ul>")
        summary_text.setHtml("".join(summary_content))
        summary_layout.addWidget(summary_text)
        
        tab_widget.addTab(summary_widget, "Summary")
        
        # Types tab
        types_widget = QtWidgets.QWidget()
        types_layout = QtWidgets.QVBoxLayout(types_widget)
        
        types_table = QtWidgets.QTableWidget()
        types_table.setColumnCount(3)
        types_table.setHorizontalHeaderLabels(["Type", "Count", "Percentage"])
        types_table.setRowCount(len(type_counts))
        
        for i, (type_name, count) in enumerate(sorted_types):
            types_table.setItem(i, 0, QtWidgets.QTableWidgetItem(type_name))
            types_table.setItem(i, 1, QtWidgets.QTableWidgetItem(str(count)))
            types_table.setItem(i, 2, QtWidgets.QTableWidgetItem(f"{count/total_items*100:.1f}%"))
        
        types_table.setSortingEnabled(True)
        types_table.resizeColumnsToContents()
        types_layout.addWidget(types_table)
        
        tab_widget.addTab(types_widget, "By Type")
        
        # Files tab
        files_widget = QtWidgets.QWidget()
        files_layout = QtWidgets.QVBoxLayout(files_widget)
        
        files_table = QtWidgets.QTableWidget()
        files_table.setColumnCount(3)
        files_table.setHorizontalHeaderLabels(["Extension", "Count", "Percentage"])
        files_table.setRowCount(len(file_ext_counts))
        
        sorted_exts = sorted(file_ext_counts.items(), key=lambda x: x[1], reverse=True)
        for i, (ext, count) in enumerate(sorted_exts):
            files_table.setItem(i, 0, QtWidgets.QTableWidgetItem(ext))
            files_table.setItem(i, 1, QtWidgets.QTableWidgetItem(str(count)))
            files_table.setItem(i, 2, QtWidgets.QTableWidgetItem(f"{count/total_items*100:.1f}%"))
        
        files_table.setSortingEnabled(True)
        files_table.resizeColumnsToContents()
        files_layout.addWidget(files_table)
        
        tab_widget.addTab(files_widget, "By File Extension")
        
        # Directories tab
        dirs_widget = QtWidgets.QWidget()
        dirs_layout = QtWidgets.QVBoxLayout(dirs_widget)
        
        dirs_table = QtWidgets.QTableWidget()
        dirs_table.setColumnCount(3)
        dirs_table.setHorizontalHeaderLabels(["Directory", "Count", "Percentage"])
        dirs_table.setRowCount(len(dir_counts))
        
        sorted_dirs = sorted(dir_counts.items(), key=lambda x: x[1], reverse=True)
        for i, (dir_name, count) in enumerate(sorted_dirs):
            dirs_table.setItem(i, 0, QtWidgets.QTableWidgetItem(dir_name))
            dirs_table.setItem(i, 1, QtWidgets.QTableWidgetItem(str(count)))
            dirs_table.setItem(i, 2, QtWidgets.QTableWidgetItem(f"{count/total_items*100:.1f}%"))
        
        dirs_table.setSortingEnabled(True)
        dirs_table.resizeColumnsToContents()
        dirs_layout.addWidget(dirs_table)
        
        tab_widget.addTab(dirs_widget, "By Directory")
        
        # Type distribution by file extension
        cross_widget = QtWidgets.QWidget()
        cross_layout = QtWidgets.QVBoxLayout(cross_widget)
        
        cross_table = QtWidgets.QTableWidget()
        
        # Get top 5 types and extensions for the cross table
        top_types = [t[0] for t in sorted_types[:5]]
        top_exts = [e[0] for e in sorted_exts[:5]]
        
        cross_table.setColumnCount(len(top_exts) + 1)
        cross_table.setRowCount(len(top_types))
        
        # Set headers
        headers = ["Type"] + top_exts
        cross_table.setHorizontalHeaderLabels(headers)
        
        # Calculate cross-tabulation
        cross_data = {}
        for row in range(total_items):
            item_type = self.model.item(row, 0).text()
            # Filename è ora in posizione 4
            filename = self.model.item(row, 4).text()
            ext = os.path.splitext(filename)[1] if filename else "unknown"
            
            if item_type in top_types and ext in top_exts:
                key = (item_type, ext)
                cross_data[key] = cross_data.get(key, 0) + 1
        
        # Fill the table
        for i, type_name in enumerate(top_types):
            cross_table.setItem(i, 0, QtWidgets.QTableWidgetItem(type_name))
            for j, ext in enumerate(top_exts):
                count = cross_data.get((type_name, ext), 0)
                cross_table.setItem(i, j + 1, QtWidgets.QTableWidgetItem(str(count)))
        
        cross_table.resizeColumnsToContents()
        cross_layout.addWidget(cross_table)
        
        tab_widget.addTab(cross_widget, "Type by Extension")
        
        # Add a close button
        button_layout = QtWidgets.QHBoxLayout()
        close_button = QtWidgets.QPushButton("Close")
        close_button.clicked.connect(dialog.accept)
        button_layout.addStretch()
        button_layout.addWidget(close_button)
        layout.addLayout(button_layout)
        
        dialog.exec_()

def main():
    file_list, filter_macros, macro_prefixes = parse_command_line_arguments()
    if not file_list:
        logging.error("No input files provided.")
        print("Usage: python cgrepgui.py [options] file_or_directory ...")
        print("Run with --help for more information.")
        sys.exit(1)
    
    logging.info(f"Starting file processing with macro filtering: {filter_macros}, prefixes: {macro_prefixes}")
    records = process_files(file_list, filter_macros, macro_prefixes)
    logging.info(f"Total records found: {len(records)}")
    
    app = QtWidgets.QApplication(sys.argv)
    window = MainWindow(records, file_list)
    window.show()
    logging.info("Application started.")
    sys.exit(app.exec_())

if __name__ == "__main__":
    main()

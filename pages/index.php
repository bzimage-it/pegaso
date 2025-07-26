<?php
// --- CONFIGURATION ---
$admin_password_file = 'pwd.secret';
if (!file_exists($admin_password_file)) {
    http_response_code(500);
    die('FATAL ERROR: Admin password file "pwd.secret" not found. Please create this file in the main directory.');
}
$admin_password = trim(file_get_contents($admin_password_file));
define('CONTENT_DIR', 'html'); // The main directory for all pages
define('TRASH_DIR', 'trash');   // The directory for deleted pages

// --- UTILITY FUNCTIONS ---
function sanitize_page_name($name) {
    $name = trim($name);
    $name = str_replace(' ', '-', $name); // Replace spaces with dashes
    return preg_replace('/[^a-zA-Z0-9_\-]/', '', $name); // Remove invalid characters
}

function get_version_id($filename) {
    return basename($filename, '.html');
}

// --- LANGUAGE SETUP ---
$supported_langs = ['en', 'it', 'fr', 'es', 'pt'];
$lang = isset($_GET['lang']) && in_array($_GET['lang'], $supported_langs) ? $_GET['lang'] : 'en';

$translations = [
    'en' => [
        'page_manager' => 'Page Manager',
        'existing_pages' => 'Existing Pages',
        'no_pages_found' => 'No pages found. Create a new one!',
        'create_new_page' => 'Create New Page',
        'page_name_placeholder' => 'page-name',
        'create_page_btn' => 'Create Page',
        'delete_page_btn' => 'Delete Page',
        'page_editor' => 'Page Editor',
        'back_to_list' => '&larr; Back to page list',
        'draft_editor' => 'Draft Editor',
        'save_draft_btn' => 'Save Draft',
        'reload_draft_btn' => 'Reload Draft',
        'word_wrap_label' => 'Word Wrap',
        'comment_placeholder' => 'Comment (optional)',
        'publish_btn' => 'Publish',
        'history' => 'History',
        'no_history_found' => 'No historical versions found.',
        'draft_status' => 'Draft',
        'published_status' => 'Published',
        'view_link' => '(View)',
        'load_to_draft_btn' => 'Load to Draft',
        'preview_btn' => 'Preview',
        'edit_comment_btn' => 'Edit Comment',
        'restore_btn' => 'Restore',
        'delete_btn' => 'Delete',
        'published_badge' => 'Published',
        'draft_badge' => 'Draft',
        'show_pwd_btn' => 'Show',
        'hide_pwd_btn' => 'Hide',
        'copy_pwd_btn' => 'Copy',
        'reset_pwd_btn' => 'Reset Password',
        'generate_pwd_btn' => 'Generate Password',
        'become_local_user_btn' => 'Become Local User',
        'js' => [
            'publish_confirm' => 'Are you sure you want to publish?',
            'load_published_confirm' => 'Loading the published version into the draft will overwrite its current content. Continue?',
            'edit_comment_prompt' => 'Enter the new comment for this version:',
            'restore_publish_confirm' => 'Are you sure you want to restore this version as published? The public file will be overwritten.',
            'load_history_confirm' => 'Loading this version into the draft will overwrite its current content. Continue?',
            'delete_confirm' => 'Are you sure you want to delete this version? Both the HTML and comment file will be removed.',
            'unsaved_changes_alert' => 'You have unsaved changes. Are you sure you want to leave?',
            'save_changes_btn' => 'Save Changes',
            'reload_draft_confirm' => 'Are you sure you want to discard all unsaved changes and reload the last saved draft?',
            'modal_title' => 'Unsaved Changes',
            'modal_text' => 'You have unsaved changes in the editor. What would you like to do?',
            'modal_save_view' => 'Save & View',
            'modal_view_saved' => 'View Saved Version',
            'modal_cancel' => 'Cancel',
            'pwd_copied_alert' => 'Password copied to clipboard!',
            'reset_pwd_confirm' => 'Are you sure you want to delete the password for this page? It will become accessible only with the admin password.',
            'delete_page_confirm' => 'Are you sure you want to move this entire page to the trash? It can only be restored via FTP.',
        ],
    ],
    'it' => [
        'page_manager' => 'Gestore Pagine',
        'existing_pages' => 'Pagine Esistenti',
        'no_pages_found' => 'Nessuna pagina trovata. Creane una nuova!',
        'create_new_page' => 'Crea Nuova Pagina',
        'page_name_placeholder' => 'nome-pagina',
        'create_page_btn' => 'Crea Pagina',
        'delete_page_btn' => 'Elimina Pagina',
        'page_editor' => 'Editor Pagina',
        'back_to_list' => '&larr; Torna alla lista pagine',
        'draft_editor' => 'Editor della Bozza',
        'save_draft_btn' => 'Salva Bozza',
        'reload_draft_btn' => 'Ricarica Bozza',
        'word_wrap_label' => 'A capo automatico',
        'comment_placeholder' => 'Commento (opzionale)',
        'publish_btn' => 'Pubblica',
        'history' => 'Cronologia',
        'no_history_found' => 'Nessuna versione storica trovata.',
        'draft_status' => 'Bozza',
        'published_status' => 'Pubblicata',
        'view_link' => '(Visualizza)',
        'load_to_draft_btn' => 'Carica in Bozza',
        'preview_btn' => 'Anteprima',
        'edit_comment_btn' => 'Mod. Commento',
        'restore_btn' => 'Ripristina',
        'delete_btn' => 'Elimina',
        'published_badge' => 'Pubblicata',
        'draft_badge' => 'Bozza',
        'show_pwd_btn' => 'Mostra',
        'hide_pwd_btn' => 'Nascondi',
        'copy_pwd_btn' => 'Copia',
        'reset_pwd_btn' => 'Reimposta Password',
        'generate_pwd_btn' => 'Genera Password',
        'become_local_user_btn' => 'Diventa Utente Locale',
        'js' => [
            'publish_confirm' => 'Sei sicuro di voler pubblicare?',
            'load_published_confirm' => 'Caricare la versione pubblicata nella bozza sovrascriverà il contenuto attuale. Continuare?',
            'edit_comment_prompt' => 'Inserisci il nuovo commento per questa versione:',
            'restore_publish_confirm' => 'Sei sicuro di voler ripristinare questa versione come pubblicata? Il file pubblico verrà sovrascritto.',
            'load_history_confirm' => 'Caricare questa versione nella bozza sovrascriverà il contenuto attuale. Continuare?',
            'delete_confirm' => 'Sei sicuro di voler eliminare questa versione? Sia il file HTML che il commento verranno rimossi.',
            'unsaved_changes_alert' => 'Hai delle modifiche non salvate. Sei sicuro di voler uscire?',
            'save_changes_btn' => 'Salva Modifiche',
            'reload_draft_confirm' => 'Sei sicuro di voler scartare tutte le modifiche non salvate e ricaricare l\'ultima bozza salvata?',
            'modal_title' => 'Modifiche non salvate',
            'modal_text' => 'Ci sono modifiche non salvate nell\'editor. Cosa vuoi fare?',
            'modal_save_view' => 'Salva e Visualizza',
            'modal_view_saved' => 'Visualizza Versione Salvata',
            'modal_cancel' => 'Annulla',
            'pwd_copied_alert' => 'Password copiata negli appunti!',
            'reset_pwd_confirm' => 'Sei sicuro di voler eliminare la password per questa pagina? Diventerà accessibile solo con la password di amministratore.',
            'delete_page_confirm' => 'Sei sicuro di voler spostare questa intera pagina nel cestino? Potrà essere ripristinata solo tramite FTP.',
        ],
    ],
    'fr' => [
        'page_manager' => 'Gestionnaire de Pages',
        'existing_pages' => 'Pages Existantes',
        'no_pages_found' => 'Aucune page trouvée. Créez-en une nouvelle !',
        'create_new_page' => 'Créer une Nouvelle Page',
        'page_name_placeholder' => 'nom-de-la-page',
        'create_page_btn' => 'Créer la Page',
        'delete_page_btn' => 'Supprimer la Page',
        'page_editor' => 'Éditeur de Page',
        'back_to_list' => '&larr; Retour à la liste des pages',
        'draft_editor' => 'Éditeur de Brouillon',
        'save_draft_btn' => 'Enregistrer le Brouillon',
        'reload_draft_btn' => 'Recharger le Brouillon',
        'word_wrap_label' => 'Retour à la ligne',
        'comment_placeholder' => 'Commentaire (optionnel)',
        'publish_btn' => 'Publier',
        'history' => 'Historique',
        'no_history_found' => 'Aucune version historique trouvée.',
        'draft_status' => 'Brouillon',
        'published_status' => 'Publiée',
        'view_link' => '(Voir)',
        'load_to_draft_btn' => 'Charger en Brouillon',
        'preview_btn' => 'Aperçu',
        'edit_comment_btn' => 'Éditer Commentaire',
        'restore_btn' => 'Restaurer',
        'delete_btn' => 'Supprimer',
        'published_badge' => 'Publiée',
        'draft_badge' => 'Brouillon',
        'show_pwd_btn' => 'Afficher',
        'hide_pwd_btn' => 'Masquer',
        'copy_pwd_btn' => 'Copier',
        'reset_pwd_btn' => 'Réinitialiser Mot de Passe',
        'generate_pwd_btn' => 'Générer Mot de Passe',
        'become_local_user_btn' => 'Devenir Utilisateur Local',
        'js' => [
            'publish_confirm' => 'Voulez-vous vraiment publier ?',
            'load_published_confirm' => 'Charger la version publiée dans le brouillon écrasera son contenu actuel. Continuer ?',
            'edit_comment_prompt' => 'Entrez le nouveau commentaire pour cette version :',
            'restore_publish_confirm' => 'Voulez-vous vraiment restaurer cette version comme publiée ? Le fichier public sera écrasé.',
            'load_history_confirm' => 'Charger cette version dans le brouillon écrasera son contenu actuel. Continuer ?',
            'delete_confirm' => 'Voulez-vous vraiment supprimer cette version ? Le fichier HTML et le fichier de commentaire seront supprimés.',
            'unsaved_changes_alert' => 'Vous avez des modifications non enregistrées. Voulez-vous vraiment quitter ?',
            'save_changes_btn' => 'Enregistrer les modifications',
            'reload_draft_confirm' => 'Voulez-vous vraiment annuler toutes les modifications non enregistrées et recharger le dernier brouillon sauvegardé ?',
            'modal_title' => 'Modifications non enregistrées',
            'modal_text' => 'Vous avez des modifications non enregistrées dans l\'éditeur. Que voulez-vous faire ?',
            'modal_save_view' => 'Enregistrer & Voir',
            'modal_view_saved' => 'Voir la Version Enregistrée',
            'modal_cancel' => 'Annuler',
            'pwd_copied_alert' => 'Mot de passe copié dans le presse-papiers !',
            'reset_pwd_confirm' => 'Voulez-vous vraiment supprimer le mot de passe de cette page ? Elle ne sera plus accessible qu\'avec le mot de passe administrateur.',
            'delete_page_confirm' => 'Voulez-vous vraiment déplacer cette page entière dans la corbeille ? Elle ne pourra être restaurée que par FTP.',
        ],
    ],
    'es' => [
        'page_manager' => 'Gestor de Páginas',
        'existing_pages' => 'Páginas Existentes',
        'no_pages_found' => 'No se encontraron páginas. ¡Crea una nueva!',
        'create_new_page' => 'Crear Nueva Página',
        'page_name_placeholder' => 'nombre-de-pagina',
        'create_page_btn' => 'Crear Página',
        'delete_page_btn' => 'Eliminar Página',
        'page_editor' => 'Editor de Página',
        'back_to_list' => '&larr; Volver a la lista de páginas',
        'draft_editor' => 'Editor de Borrador',
        'save_draft_btn' => 'Guardar Borrador',
        'reload_draft_btn' => 'Recargar Borrador',
        'word_wrap_label' => 'Ajuste de línea',
        'comment_placeholder' => 'Comentario (opcional)',
        'publish_btn' => 'Publicar',
        'history' => 'Historial',
        'no_history_found' => 'No se encontraron versiones en el historial.',
        'draft_status' => 'Borrador',
        'published_status' => 'Publicada',
        'view_link' => '(Ver)',
        'load_to_draft_btn' => 'Cargar en Borrador',
        'preview_btn' => 'Vista Previa',
        'edit_comment_btn' => 'Editar Comentario',
        'restore_btn' => 'Restaurar',
        'delete_btn' => 'Eliminar',
        'published_badge' => 'Publicada',
        'draft_badge' => 'Borrador',
        'show_pwd_btn' => 'Mostrar',
        'hide_pwd_btn' => 'Ocultar',
        'copy_pwd_btn' => 'Copiar',
        'reset_pwd_btn' => 'Restablecer Contraseña',
        'generate_pwd_btn' => 'Generar Contraseña',
        'become_local_user_btn' => 'Ser Usuario Local',
        'js' => [
            'publish_confirm' => '¿Está seguro de que desea publicar?',
            'load_published_confirm' => 'Cargar la versión publicada en el borrador sobrescribirá su contenido actual. ¿Continuar?',
            'edit_comment_prompt' => 'Ingrese el nuevo comentario para esta versión:',
            'restore_publish_confirm' => '¿Está seguro de que desea restaurar esta versión como publicada? El archivo público será sobrescrito.',
            'load_history_confirm' => 'Cargar esta versión en el borrador sobrescribirá su contenido actual. ¿Continuar?',
            'delete_confirm' => '¿Está seguro de que desea eliminar esta versión? Se eliminarán tanto el archivo HTML como el de comentario.',
            'unsaved_changes_alert' => 'Tiene cambios sin guardar. ¿Está seguro de que desea salir?',
            'save_changes_btn' => 'Guardar Cambios',
            'reload_draft_confirm' => '¿Está seguro de que desea descartar todos los cambios no guardados y recargar el último borrador guardado?',
            'modal_title' => 'Cambios sin guardar',
            'modal_text' => 'Tiene cambios sin guardar en el editor. ¿Qué le gustaría hacer?',
            'modal_save_view' => 'Guardar y Ver',
            'modal_view_saved' => 'Ver Versión Guardada',
            'modal_cancel' => 'Cancelar',
            'pwd_copied_alert' => '¡Contraseña copiada al portapapeles!',
            'reset_pwd_confirm' => '¿Está seguro de que desea eliminar la contraseña de esta página? Solo será accesible con la contraseña de administrador.',
            'delete_page_confirm' => '¿Está seguro de que desea mover esta página completa a la papelera? Solo se podrá restaurar a través de FTP.',
        ],
    ],
    'pt' => [
        'page_manager' => 'Gestor de Páginas',
        'existing_pages' => 'Páginas Existentes',
        'no_pages_found' => 'Nenhuma página encontrada. Crie uma nova!',
        'create_new_page' => 'Criar Nova Página',
        'page_name_placeholder' => 'nome-da-pagina',
        'create_page_btn' => 'Criar Página',
        'delete_page_btn' => 'Excluir Página',
        'page_editor' => 'Editor de Página',
        'back_to_list' => '&larr; Voltar à lista de páginas',
        'draft_editor' => 'Editor de Rascunho',
        'save_draft_btn' => 'Salvar Rascunho',
        'reload_draft_btn' => 'Recarregar Rascunho',
        'word_wrap_label' => 'Quebra de linha',
        'comment_placeholder' => 'Comentário (opcional)',
        'publish_btn' => 'Publicar',
        'history' => 'Histórico',
        'no_history_found' => 'Nenhuma versão histórica encontrada.',
        'draft_status' => 'Rascunho',
        'published_status' => 'Publicada',
        'view_link' => '(Ver)',
        'load_to_draft_btn' => 'Carregar para Rascunho',
        'preview_btn' => 'Pré-visualizar',
        'edit_comment_btn' => 'Editar Comentário',
        'restore_btn' => 'Restaurar',
        'delete_btn' => 'Excluir',
        'published_badge' => 'Publicada',
        'draft_badge' => 'Rascunho',
        'show_pwd_btn' => 'Mostrar',
        'hide_pwd_btn' => 'Ocultar',
        'copy_pwd_btn' => 'Copiar',
        'reset_pwd_btn' => 'Redefinir Senha',
        'generate_pwd_btn' => 'Gerar Senha',
        'become_local_user_btn' => 'Tornar-se Usuário Local',
        'js' => [
            'publish_confirm' => 'Tem certeza de que deseja publicar?',
            'load_published_confirm' => 'Carregar a versão publicada no rascunho irá sobrescrever o conteúdo atual. Continuar?',
            'edit_comment_prompt' => 'Digite o novo comentário para esta versão:',
            'restore_publish_confirm' => 'Tem certeza de que deseja restaurar esta versão como publicada? O arquivo público será sobrescrito.',
            'load_history_confirm' => 'Carregar esta versão para o rascunho irá sobrescrever o conteúdo atual. Continuar?',
            'delete_confirm' => 'Tem certeza de que deseja excluir esta versão? Tanto o arquivo HTML quanto o de comentário serão removidos.',
            'unsaved_changes_alert' => 'Você tem alterações não salvas. Tem certeza de que deseja sair?',
            'save_changes_btn' => 'Salvar Alterações',
            'reload_draft_confirm' => 'Tem certeza de que deseja descartar todas as alterações não salvas e recarregar o último rascunho salvo?',
            'modal_title' => 'Alterações não salvas',
            'modal_text' => 'Você tem alterações não salvas no editor. O que você gostaria de fazer?',
            'modal_save_view' => 'Salvar e Ver',
            'modal_view_saved' => 'Ver Versão Salva',
            'modal_cancel' => 'Cancelar',
            'pwd_copied_alert' => 'Senha copiada para a área de transferência!',
            'reset_pwd_confirm' => 'Tem certeza de que deseja excluir a senha desta página? Ela só ficará acessível com a senha de administrador.',
            'delete_page_confirm' => 'Tem certeza de que deseja mover esta página inteira para a lixeira? Ela só poderá ser restaurada via FTP.',
        ],
    ],
];
$i18n = $translations[$lang];

// --- PASSWORD AUTHENTICATION ---
$page_name = isset($_GET['page']) ? sanitize_page_name($_GET['page']) : null;
$user_pwd = $_GET['pwd'] ?? null;

if (is_null($user_pwd)) {
    http_response_code(403);
    die('Error: Missing password.');
}

$is_authorized = false;
$is_admin = ($user_pwd === $admin_password);

if ($page_name && is_dir(CONTENT_DIR . '/' . $page_name)) {
    // Editor view: Check page-specific password first, then admin password.
    $page_password_file = CONTENT_DIR . '/' . $page_name . '/pwd.secret';
    if (file_exists($page_password_file)) {
        $page_password = trim(file_get_contents($page_password_file));
        if ($user_pwd === $page_password) {
            $is_authorized = true;
        }
    }
    // If not authorized by page password, fall back to checking admin password.
    if (!$is_authorized && $is_admin) {
        $is_authorized = true;
    }
} else {
    // Manager view (no page specified) or invalid page: Only admin password works.
    if ($is_admin) {
        $is_authorized = true;
    }
}

if (!$is_authorized) {
    http_response_code(403);
    die('Error: Incorrect password.');
}

// --- INITIAL SETUP ---
if (!file_exists(CONTENT_DIR)) {
    if (!mkdir(CONTENT_DIR, 0755, true)) {
        die('Error: Could not create the main directory "' . CONTENT_DIR . '". Check permissions.');
    }
}
if (!file_exists(TRASH_DIR)) {
    if (!mkdir(TRASH_DIR, 0755, true)) {
        die('Error: Could not create the trash directory "' . TRASH_DIR . '". Check permissions.');
    }
}


session_start();
$csrf_token = $_SESSION['csrf_token'] ?? bin2hex(random_bytes(32));
$_SESSION['csrf_token'] = $csrf_token;

$pwd = $_GET['pwd'];

// Calculate the base path for assets and links, making it robust against URL rewriting
$base_path = rtrim(dirname($_SERVER['SCRIPT_NAME']), '/\\');
$base_url = $_SERVER['PHP_SELF'] . '?pwd=' . urlencode($pwd) . '&lang=' . $lang;


// --- POST REQUEST HANDLING LOGIC ---
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    if (!isset($_POST['csrf_token']) || !hash_equals($_SESSION['csrf_token'], $_POST['csrf_token'])) {
        die('CSRF token error.');
    }

    $action = $_POST['action'];

    // --- Admin-only actions for the manager page ---
    if ($is_admin) {
        if ($action === 'create_page' && isset($_POST['new_page_name'])) {
            $new_page_name = sanitize_page_name($_POST['new_page_name']);
            if (!empty($new_page_name)) {
                $new_page_path = CONTENT_DIR . '/' . $new_page_name;
                if (!file_exists($new_page_path)) {
                    mkdir($new_page_path, 0755, true);
                }
            }
            header("Location: " . $base_url);
            exit();
        }
        if ($action === 'reset_page_password' && isset($_POST['page_to_manage'])) {
            $page_to_manage = sanitize_page_name($_POST['page_to_manage']);
            $pwd_file = CONTENT_DIR . '/' . $page_to_manage . '/pwd.secret';
            if (file_exists($pwd_file)) {
                unlink($pwd_file);
            }
            header("Location: " . $base_url);
            exit();
        }
        if ($action === 'generate_page_password' && isset($_POST['page_to_manage'])) {
            $page_to_manage = sanitize_page_name($_POST['page_to_manage']);
            $pwd_file = CONTENT_DIR . '/' . $page_to_manage . '/pwd.secret';
            $new_password = bin2hex(random_bytes(8)); // 16 chars
            file_put_contents($pwd_file, $new_password);
            header("Location: " . $base_url);
            exit();
        }
        if ($action === 'delete_page' && isset($_POST['page_to_manage'])) {
            $page_to_manage = sanitize_page_name($_POST['page_to_manage']);
            $source_dir = CONTENT_DIR . '/' . $page_to_manage;
            if (is_dir($source_dir)) {
                date_default_timezone_set('Europe/Rome');
                $dest_dir = TRASH_DIR . '/' . date('Y-m-d_H-i-s') . '_' . $page_to_manage;
                rename($source_dir, $dest_dir);
            }
            header("Location: " . $base_url);
            exit();
        }
    }


    // --- Actions within a specific page editor ---
    if ($page_name) {
        $page_path = CONTENT_DIR . '/' . $page_name . '/';
        if (!is_dir($page_path)) die('Invalid page.');

        $draft_file = $page_path . 'draft.html';
        $pub_file = $page_path . 'content.html';
        $state_file = $page_path . '_published_state.txt';
        $draft_state_file = $page_path . '_draft_state.txt';

        switch ($action) {
            case 'save_draft':
                if (isset($_POST['content'])) {
                    file_put_contents($draft_file, $_POST['content']);
                    if (file_exists($draft_state_file)) {
                        unlink($draft_state_file);
                    }
                }
                break;
            case 'publish':
                if (isset($_POST['content'])) {
                    file_put_contents($draft_file, $_POST['content']);
                    
                    date_default_timezone_set('Europe/Rome');
                    $date_format = 'Y-m-d_H-i-s';
                    $version_id = date($date_format);
                    
                    $historical_file = $page_path . $version_id . ".html";
                    copy($draft_file, $historical_file);
                    copy($draft_file, $pub_file);
                    
                    $comment = isset($_POST['comment']) ? trim($_POST['comment']) : '';
                    if (!empty($comment)) {
                        $comment_file = $page_path . $version_id . ".comment";
                        file_put_contents($comment_file, $comment);
                    }
                    
                    file_put_contents($state_file, $version_id);
                    file_put_contents($draft_state_file, $version_id);
                }
                break;
            case 'restore': // Load into draft
                if (isset($_POST['file'])) {
                    $source_file = $page_path . basename($_POST['file']);
                    if (file_exists($source_file) && is_file($source_file)) {
                        copy($source_file, $draft_file);
                        
                        if (basename($_POST['file']) !== 'content.html') {
                            $version_id = get_version_id($_POST['file']);
                            file_put_contents($draft_state_file, $version_id);
                        } else {
                            if (file_exists($state_file)) {
                                file_put_contents($draft_state_file, trim(file_get_contents($state_file)));
                            } else {
                                if(file_exists($draft_state_file)) unlink($draft_state_file);
                            }
                        }
                    }
                }
                break;
            case 'restore_publish': // Restore directly as published
                if (isset($_POST['file'])) {
                    $source_file = $page_path . basename($_POST['file']);
                    if (file_exists($source_file) && is_file($source_file)) {
                        copy($source_file, $pub_file);
                        $version_id = get_version_id($_POST['file']);
                        file_put_contents($state_file, $version_id);
                    }
                }
                break;
            case 'delete':
                if (isset($_POST['file'])) {
                    $version_id = get_version_id($_POST['file']);
                    $file_html = $page_path . $version_id . '.html';
                    $file_comment = $page_path . $version_id . '.comment';

                    if (file_exists($file_html)) {
                        if (file_exists($state_file) && trim(file_get_contents($state_file)) === $version_id) unlink($state_file);
                        if (file_exists($draft_state_file) && trim(file_get_contents($draft_state_file)) === $version_id) unlink($draft_state_file);
                        
                        unlink($file_html);
                        if (file_exists($file_comment)) unlink($file_comment);
                    }
                }
                break;
            case 'edit_comment':
                 if (isset($_POST['file']) && isset($_POST['new_comment'])) {
                    $version_id = get_version_id($_POST['file']);
                    $comment_file = $page_path . $version_id . '.comment';
                    $new_comment = trim($_POST['new_comment']);

                    if (!empty($new_comment)) {
                        file_put_contents($comment_file, $new_comment);
                    } else {
                        if (file_exists($comment_file)) {
                            unlink($comment_file);
                        }
                    }
                }
                break;
        }
        header("Location: " . $base_url . '&page=' . $page_name);
        exit();
    }
}
?>
<!DOCTYPE html>
<html lang="<?php echo $lang; ?>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo $i18n['page_manager']; ?></title>
    
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; background-color: #f4f7f9; color: #333; margin: 0; padding: 20px; }
        .container { max-width: 1000px; margin: 20px auto; background: #fff; padding: 20px 30px; border-radius: 8px; box-shadow: 0 4px 10px rgba(0,0,0,0.05); }
        h1, h2 { color: #2c3e50; border-bottom: 2px solid #e0e0e0; padding-bottom: 10px; }
        h2 { margin-top: 40px; }
        a { color: #3498db; text-decoration: none; }
        a:hover { text-decoration: underline; }
        button, .btn-link { cursor: pointer; border: none; padding: 10px 18px; border-radius: 5px; font-size: 14px; font-weight: bold; transition: all 0.2s ease; display: inline-block; text-align: center;}
        button:disabled { background-color: #bdc3c7; cursor: not-allowed; }
        input[type="text"], select { border: 1px solid #ccc; padding: 9px; border-radius: 5px; font-size: 14px; }
        .btn-primary { background-color: #3498db; color: white; }
        .btn-primary:hover:not(:disabled) { background-color: #2980b9; }
        .btn-secondary { background-color: #bdc3c7; color: #fff; }
        .btn-secondary:hover:not(:disabled) { background-color: #95a5a6; }
        .btn-delete { background-color: #e74c3c; color: white; }
        .btn-delete:hover:not(:disabled) { background-color: #c0392b; }
        .page-list-item { display: flex; justify-content: space-between; align-items: center; background-color: #ecf0f1; margin-bottom: 10px; padding: 15px; border-radius: 5px; flex-wrap: wrap; gap: 10px;}
        .page-list-item-name { font-size: 18px; font-weight: bold; flex-grow: 1;}
        .page-list-item-actions { display: flex; gap: 8px; align-items: center; flex-wrap: wrap;}
        .pwd-area { display: flex; gap: 5px; align-items: center; background-color: #fff; padding: 5px; border-radius: 5px;}
        .pwd-text { font-family: monospace; background: #f0f0f0; padding: 2px 6px; border-radius: 3px; }
        .pwd-text.is-hidden { filter: blur(4px); user-select: none; }
        .form-group { margin-top: 20px; display: flex; gap: 10px; align-items: center; }
    </style>
    
    <?php if ($page_name): // Styles and JS for the editor only ?>
    <link rel="stylesheet" href="<?php echo htmlspecialchars($base_path); ?>/lib/codemirror.css">
    <link rel="stylesheet" href="<?php echo htmlspecialchars($base_path); ?>/theme/material.css">
    <style>
        .main-status-bar { display: flex; justify-content: space-between; background-color: #ecf0f1; padding: 15px; border-radius: 8px; margin-bottom: 30px; flex-wrap: wrap; gap: 20px; }
        .status-section { display: flex; align-items: center; gap: 10px; padding: 10px; border-radius: 6px; flex-grow: 1; justify-content: center; }
        .status-section.lang-switcher, .status-section.role-switcher { flex-grow: 0; }
        .status-section strong { font-size: 16px; }
        .status-dot { width: 12px; height: 12px; border-radius: 50%; flex-shrink: 0;}
        .dot-green { background-color: #2ecc71; } .dot-gray { background-color: #95a5a6; } .dot-blue { background-color: #3498db; } .dot-orange { background-color: #f39c12; }
        
        .editor-area { display: flex; flex-direction: column; }
        .actions { display: flex; gap: 10px; flex-wrap: wrap; align-items: center; margin-top: 15px; }
        .publish-controls { display: flex; gap: 10px; flex-grow: 1; }
        .publish-controls input[type="text"] { flex-grow: 1; }
        .editor-options { display: flex; align-items: center; gap: 5px; margin-left: auto; }
        .btn-publish { background-color: #2ecc71; color: white; } .btn-publish:hover:not(:disabled) { background-color: #27ae60; }
        .btn-load-draft { background-color: #f39c12; color: white; } .btn-load-draft:hover:not(:disabled) { background-color: #e67e22; }
        .btn-restore-publish { background-color: #8e44ad; color: white; } .btn-restore-publish:hover:not(:disabled) { background-color: #732d91; }
        .btn-edit-comment { background-color: #95a5a6; color: white; } .btn-edit-comment:hover:not(:disabled) { background-color: #7f8c8d; }
        .btn-save-dirty { background-color: #e67e22; color: white; }
        .btn-load-draft-small { padding: 4px 8px; font-size: 12px; margin-left: 5px; vertical-align: middle; }
        .file-list li { display: flex; justify-content: space-between; align-items: center; padding: 12px; border-bottom: 1px solid #eee; transition: background-color 0.2s; background-color: transparent; margin: 0; border-left: 4px solid transparent; }
        .file-list li:hover { background-color: #f9f9f9; }
        .file-list li.published-version { background-color: #e8f5e9; border-left-color: #4caf50; }
        .file-list .file-info { font-family: "Courier New", monospace; word-break: break-all; padding-right: 15px; font-size: 14px; flex-grow: 1;}
        .file-comment { color: #7f8c8d; font-style: italic; }
        .badge { font-size: 10px; font-weight: bold; padding: 2px 6px; border-radius: 10px; margin-left: 10px; vertical-align: middle; text-transform: uppercase; color: white; }
        .published-badge { background-color: #2ecc71; }
        .draft-badge { background-color: #f39c12; }
        .file-actions { display: flex; gap: 5px; flex-wrap: wrap; align-items: center; flex-shrink: 0; } .file-actions form { display: inline-block; margin: 0; }
        .file-link { text-decoration: none; color: #3498db; font-weight: bold; background-color: #e0e0e0; padding: 5px 10px; border-radius: 5px; font-size: 12px; }
        .file-link:hover { background-color: #d1d1d1; }
        .CodeMirror { 
            border: 1px solid #ccc; 
            border-radius: 5px; 
            height: 400px; /* Initial height */
            font-size: 14px;
            resize: vertical;
        }

        /* Custom Modal Styles */
        .modal-overlay { display: none; position: fixed; z-index: 1000; left: 0; top: 0; width: 100%; height: 100%; overflow: auto; background-color: rgba(0,0,0,0.4); justify-content: center; align-items: center;}
        .modal-content { background-color: #fefefe; margin: auto; padding: 20px; border: 1px solid #888; width: 80%; max-width: 500px; border-radius: 8px; box-shadow: 0 5px 15px rgba(0,0,0,0.3); text-align: center; }
        .modal-content h3 { margin-top: 0; }
        .modal-actions { margin-top: 20px; display: flex; justify-content: center; gap: 10px; flex-wrap: wrap;}
    </style>
    <script src="<?php echo htmlspecialchars($base_path); ?>/lib/codemirror.js"></script>
    <script src="<?php echo htmlspecialchars($base_path); ?>/mode/xml/xml.js"></script>
    <script src="<?php echo htmlspecialchars($base_path); ?>/mode/javascript/javascript.js"></script>
    <script src="<?php echo htmlspecialchars($base_path); ?>/mode/css/css.js"></script>
    <script src="<?php echo htmlspecialchars($base_path); ?>/mode/htmlmixed/htmlmixed.js"></script>
    <?php endif; ?>
</head>
<body>
<div class="container">

<?php if (!$page_name): // --- MANAGER VIEW --- ?>
    <h1><?php echo $i18n['page_manager']; ?></h1>
    <h2><?php echo $i18n['existing_pages']; ?></h2>
    <div class="page-list">
    <?php
        $pages = array_filter(glob(CONTENT_DIR . '/*'), 'is_dir');
        if (empty($pages)) {
            echo "<p>" . $i18n['no_pages_found'] . "</p>";
        } else {
            foreach ($pages as $page_path) {
                $current_page_name = basename($page_path);
    ?>
        <div class="page-list-item">
            <a class="page-list-item-name" href="<?php echo $base_url . '&page=' . $current_page_name; ?>"><?php echo htmlspecialchars($current_page_name); ?></a>
            
            <?php if ($is_admin): ?>
            <div class="page-list-item-actions">
                <form action="<?php echo $base_url; ?>" method="post" onsubmit="return confirm('<?php echo $i18n['js']['delete_page_confirm']; ?>');" style="display:inline;">
                    <input type="hidden" name="action" value="delete_page">
                    <input type="hidden" name="page_to_manage" value="<?php echo $current_page_name; ?>">
                    <input type="hidden" name="csrf_token" value="<?php echo $csrf_token; ?>">
                    <button type="submit" class="btn-delete"><?php echo $i18n['delete_page_btn']; ?></button>
                </form>
                <?php
                    $page_pwd_file = $page_path . '/pwd.secret';
                    if (file_exists($page_pwd_file)) {
                        $page_pwd = trim(file_get_contents($page_pwd_file));
                ?>
                    <div class="pwd-area">
                        <span class="pwd-text is-hidden" id="pwd-text-<?php echo $current_page_name; ?>"><?php echo htmlspecialchars($page_pwd); ?></span>
                        <button type="button" class="btn-secondary" onclick="togglePasswordVisibility('<?php echo $current_page_name; ?>')" id="btn-show-<?php echo $current_page_name; ?>"><?php echo $i18n['show_pwd_btn']; ?></button>
                        <button type="button" class="btn-secondary" onclick="copyPasswordToClipboard('<?php echo $current_page_name; ?>')"><?php echo $i18n['copy_pwd_btn']; ?></button>
                    </div>
                    <form action="<?php echo $base_url; ?>" method="post" onsubmit="return confirm('<?php echo $i18n['js']['reset_pwd_confirm']; ?>');" style="display:inline;">
                        <input type="hidden" name="action" value="reset_page_password">
                        <input type="hidden" name="page_to_manage" value="<?php echo $current_page_name; ?>">
                        <input type="hidden" name="csrf_token" value="<?php echo $csrf_token; ?>">
                        <button type="submit" class="btn-delete"><?php echo $i18n['reset_pwd_btn']; ?></button>
                    </form>
                <?php } else { ?>
                    <form action="<?php echo $base_url; ?>" method="post" style="display:inline;">
                        <input type="hidden" name="action" value="generate_page_password">
                        <input type="hidden" name="page_to_manage" value="<?php echo $current_page_name; ?>">
                        <input type="hidden" name="csrf_token" value="<?php echo $csrf_token; ?>">
                        <button type="submit" class="btn-primary"><?php echo $i18n['generate_pwd_btn']; ?></button>
                    </form>
                <?php } ?>
            </div>
            <?php endif; ?>
        </div>
    <?php
            }
        }
    ?>
    </div>
    
    <?php if ($is_admin): ?>
    <h2><?php echo $i18n['create_new_page']; ?></h2>
    <form action="<?php echo $base_url; ?>" method="post" class="form-group">
        <input type="hidden" name="action" value="create_page">
        <input type="hidden" name="csrf_token" value="<?php echo $csrf_token; ?>">
        <input type="text" name="new_page_name" placeholder="<?php echo $i18n['page_name_placeholder']; ?>" required>
        <button type="submit" class="btn-primary"><?php echo $i18n['create_page_btn']; ?></button>
    </form>
    <?php endif; ?>
    
    <script>
        const i18nJs = <?php echo json_encode($i18n); ?>;

        function togglePasswordVisibility(pageName) {
            const pwdSpan = document.getElementById(`pwd-text-${pageName}`);
            const showBtn = document.getElementById(`btn-show-${pageName}`);
            if (pwdSpan.classList.contains('is-hidden')) {
                pwdSpan.classList.remove('is-hidden');
                showBtn.innerText = i18nJs.hide_pwd_btn;
            } else {
                pwdSpan.classList.add('is-hidden');
                showBtn.innerText = i18nJs.show_pwd_btn;
            }
        }
        function copyPasswordToClipboard(pageName) {
            const pwdText = document.getElementById(`pwd-text-${pageName}`).innerText;
            navigator.clipboard.writeText(pwdText).then(() => {
                alert(i18nJs.js.pwd_copied_alert);
            }, (err) => {
                console.error('Could not copy text: ', err);
            });
        }
    </script>

<?php else: // --- EDITOR VIEW --- ?>
    <?php
        $page_path = CONTENT_DIR . '/' . $page_name . '/';
        $draft_file = $page_path . 'draft.html';
        $pub_file = $page_path . 'content.html';
        $state_file = $page_path . '_published_state.txt';
        $draft_state_file = $page_path . '_draft_state.txt';
        $action_url = $base_url . '&page=' . $page_name;
        
        $draft_exists = file_exists($draft_file);
        $pub_exists = file_exists($pub_file);
        $draft_content = $draft_exists ? htmlspecialchars(file_get_contents($draft_file)) : '';
        
        $published_version_id = file_exists($state_file) ? trim(file_get_contents($state_file)) : null;
        $draft_version_id = file_exists($draft_state_file) ? trim(file_get_contents($draft_state_file)) : null;

        // Get page-specific password if it exists
        $page_password_file = $page_path . 'pwd.secret';
        $page_password = file_exists($page_password_file) ? trim(file_get_contents($page_password_file)) : null;

        $html_files = glob($page_path . '*.html');
        $historical_files = array_filter($html_files, function($file) {
            return preg_match('/^\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}\.html$/', basename($file));
        });
        usort($historical_files, function($a, $b) {
            return strcmp(basename($b), basename($a));
        });
    ?>
    <h1><?php echo $i18n['page_editor']; ?>: <code><?php echo htmlspecialchars($page_name); ?></code></h1>
    <?php if ($is_admin): ?>
    <p><a href="<?php echo $base_url; ?>"><?php echo $i18n['back_to_list']; ?></a></p>
    <?php endif; ?>

    <!-- Status Bar -->
    <div class="main-status-bar">
        <div class="status-section">
            <?php
            $draft_dot_class = 'dot-gray';
            if ($draft_exists) {
                $draft_dot_class = $draft_version_id ? 'dot-blue' : 'dot-green';
            }
            ?>
            <span id="draft-status-dot" class="status-dot <?php echo $draft_dot_class; ?>"></span>
            <strong><?php echo $i18n['draft_status']; ?></strong>
            <?php if ($draft_exists): ?>
                <a href="<?php echo htmlspecialchars($base_path . '/' . CONTENT_DIR . '/' . $page_name . '/draft.html'); ?>" target="_blank" id="view-draft-link" class="file-link"><?php echo $i18n['view_link']; ?></a>
            <?php endif; ?>
        </div>
        <div class="status-section">
            <span class="status-dot <?php echo $pub_exists ? 'dot-green' : 'dot-gray'; ?>"></span>
            <strong><?php echo $i18n['published_status']; ?></strong>
            <?php if ($pub_exists): ?>
                <a href="<?php echo htmlspecialchars($base_path . '/' . CONTENT_DIR . '/' . $page_name . '/content.html'); ?>" target="_blank" class="file-link"><?php echo $i18n['view_link']; ?></a>
                <form action="<?php echo $action_url; ?>" method="post" onsubmit="return confirm('<?php echo $i18n['js']['load_published_confirm']; ?>');">
                    <input type="hidden" name="action" value="restore">
                    <input type="hidden" name="file" value="content.html">
                    <input type="hidden" name="csrf_token" value="<?php echo $csrf_token; ?>">
                    <button type="submit" class="btn-load-draft btn-load-draft-small"><?php echo $i18n['load_to_draft_btn']; ?></button>
                </form>
            <?php endif; ?>
        </div>
        
        <?php if ($is_admin && $page_password): ?>
        <div class="status-section role-switcher">
            <a href="<?php echo $_SERVER['PHP_SELF'] . '?pwd=' . urlencode($page_password) . '&lang=' . $lang . '&page=' . urlencode($page_name); ?>" class="btn-link btn-secondary"><?php echo $i18n['become_local_user_btn']; ?></a>
        </div>
        <?php endif; ?>

        <div class="status-section lang-switcher">
            <form action="<?php echo $_SERVER['PHP_SELF']; ?>" method="get" id="lang-form">
                <input type="hidden" name="pwd" value="<?php echo urlencode($pwd); ?>">
                <input type="hidden" name="page" value="<?php echo urlencode($page_name); ?>">
                <select name="lang" id="lang-select" onchange="this.form.submit()">
                    <option value="en" <?php if ($lang === 'en') echo 'selected'; ?>>English</option>
                    <option value="it" <?php if ($lang === 'it') echo 'selected'; ?>>Italiano</option>
                    <option value="fr" <?php if ($lang === 'fr') echo 'selected'; ?>>Français</option>
                    <option value="es" <?php if ($lang === 'es') echo 'selected'; ?>>Español</option>
                    <option value="pt" <?php if ($lang === 'pt') echo 'selected'; ?>>Português</option>
                </select>
            </form>
        </div>
    </div>


    <!-- Editor Section -->
    <h2><?php echo $i18n['draft_editor']; ?></h2>
    <div class="editor-area">
        <form action="<?php echo $action_url; ?>" method="post" id="editor-form">
            <input type="hidden" name="csrf_token" value="<?php echo $csrf_token; ?>">
            <textarea name="content" id="html-editor"><?php echo $draft_content; ?></textarea>
            
            <div class="actions">
                <button type="submit" name="action" value="save_draft" id="save-draft-btn" class="btn-primary"><?php echo $i18n['save_draft_btn']; ?></button>
                <button type="button" id="reload-draft-btn" class="btn-secondary" disabled><?php echo $i18n['reload_draft_btn']; ?></button>
                <div class="publish-controls">
                    <input type="text" name="comment" placeholder="<?php echo $i18n['comment_placeholder']; ?>">
                    <button type="submit" name="action" value="publish" class="btn-publish" onclick="return confirm('<?php echo $i18n['js']['publish_confirm']; ?>');"><?php echo $i18n['publish_btn']; ?></button>
                </div>
                <div class="editor-options">
                    <input type="checkbox" id="word-wrap-toggle">
                    <label for="word-wrap-toggle"><?php echo $i18n['word_wrap_label']; ?></label>
                </div>
            </div>
        </form>
    </div>
    
    <!-- Historical Versions -->
    <h2><?php echo $i18n['history']; ?></h2>
    <?php if (empty($historical_files)): ?>
        <p><?php echo $i18n['no_history_found']; ?></p>
    <?php else: ?>
        <ul class="file-list">
            <?php foreach ($historical_files as $file): 
                $version_id = get_version_id($file);
                $comment_file = $page_path . $version_id . '.comment';
                $comment_text = file_exists($comment_file) ? trim(file_get_contents($comment_file)) : '';
            ?>
                <li class="<?php echo ($version_id === $published_version_id) ? 'published-version' : ''; ?>">
                    <div class="file-info">
                        <?php echo htmlspecialchars(basename($file)); ?>
                        <?php if(!empty($comment_text)): ?>
                            <span class="file-comment">- "<?php echo htmlspecialchars($comment_text); ?>"</span>
                        <?php endif; ?>
                        <?php if ($version_id === $published_version_id): ?>
                            <span class="badge published-badge"><?php echo $i18n['published_badge']; ?></span>
                        <?php endif; ?>
                        <?php if ($version_id === $draft_version_id): ?>
                            <span class="badge draft-badge"><?php echo $i18n['draft_badge']; ?></span>
                        <?php endif; ?>
                    </div>
                    <div class="file-actions">
                        <a href="<?php echo htmlspecialchars($base_path . '/' . CONTENT_DIR . '/' . $page_name . '/' . basename($file)); ?>" target="_blank" class="file-link"><?php echo $i18n['preview_btn']; ?></a>
                         <button type="button" class="btn-edit-comment" onclick="editComment('<?php echo htmlspecialchars(basename($file)); ?>', '<?php echo htmlspecialchars($comment_text); ?>')"><?php echo $i18n['edit_comment_btn']; ?></button>
                        <form action="<?php echo $action_url; ?>" method="post" onsubmit="return confirm('<?php echo $i18n['js']['restore_publish_confirm']; ?>');">
                            <input type="hidden" name="action" value="restore_publish"><input type="hidden" name="file" value="<?php echo htmlspecialchars(basename($file)); ?>">
                            <input type="hidden" name="csrf_token" value="<?php echo $csrf_token; ?>"><button type="submit" class="btn-restore-publish" <?php if ($version_id === $published_version_id) echo 'disabled'; ?>><?php echo $i18n['restore_btn']; ?></button>
                        </form>
                        <form action="<?php echo $action_url; ?>" method="post" onsubmit="return confirm('<?php echo $i18n['js']['load_history_confirm']; ?>');">
                            <input type="hidden" name="action" value="restore"><input type="hidden" name="file" value="<?php echo htmlspecialchars(basename($file)); ?>">
                            <input type="hidden" name="csrf_token" value="<?php echo $csrf_token; ?>"><button type="submit" class="btn-load-draft"><?php echo $i18n['load_to_draft_btn']; ?></button>
                        </form>
                        <form action="<?php echo $action_url; ?>" method="post" onsubmit="return confirm('<?php echo $i18n['js']['delete_confirm']; ?>');">
                            <input type="hidden" name="action" value="delete"><input type="hidden" name="file" value="<?php echo htmlspecialchars(basename($file)); ?>">
                            <input type="hidden" name="csrf_token" value="<?php echo $csrf_token; ?>"><button type="submit" class="btn-delete"><?php echo $i18n['delete_btn']; ?></button>
                        </form>
                    </div>
                </li>
            <?php endforeach; ?>
        </ul>
    <?php endif; ?>
    
    <!-- Custom Modal -->
    <div id="view-draft-modal" class="modal-overlay">
        <div class="modal-content">
            <h3 id="modal-title"></h3>
            <p id="modal-text"></p>
            <div class="modal-actions">
                <button id="modal-save-btn" class="btn-publish"></button>
                <button id="modal-view-saved-btn" class="btn-load-draft"></button>
                <button id="modal-cancel-btn" class="btn-secondary"></button>
            </div>
        </div>
    </div>
    
    <script>
        const i18n = <?php echo json_encode($i18n['js']); ?>;

        function editComment(fileName, oldComment) {
            const newComment = prompt(i18n.edit_comment_prompt, oldComment);

            if (newComment !== null) { // User didn't click cancel
                const form = document.createElement('form');
                form.method = 'post';
                form.action = '<?php echo $action_url; ?>';
                form.innerHTML = `
                    <input type="hidden" name="action" value="edit_comment">
                    <input type="hidden" name="file" value="${fileName}">
                    <input type="hidden" name="new_comment" value="${newComment}">
                    <input type="hidden" name="csrf_token" value="<?php echo $csrf_token; ?>">
                `;
                document.body.appendChild(form);
                form.submit();
            }
        }

        document.addEventListener("DOMContentLoaded", function() {
            var editor = CodeMirror.fromTextArea(document.getElementById("html-editor"), {
                lineNumbers: true, 
                mode: "htmlmixed", 
                theme: "material", 
                lineWrapping: false
            });

            // This is required to make the form submission work with CodeMirror
            editor.save(); 

            let isDirty = false;
            const saveBtn = document.getElementById('save-draft-btn');
            const reloadBtn = document.getElementById('reload-draft-btn');
            const draftDot = document.getElementById('draft-status-dot');
            const viewDraftLink = document.getElementById('view-draft-link');
            const editorForm = document.getElementById('editor-form');
            const wordWrapToggle = document.getElementById('word-wrap-toggle');

            // Custom Modal elements
            const modal = document.getElementById('view-draft-modal');
            const modalTitle = document.getElementById('modal-title');
            const modalText = document.getElementById('modal-text');
            const modalSaveBtn = document.getElementById('modal-save-btn');
            const modalViewSavedBtn = document.getElementById('modal-view-saved-btn');
            const modalCancelBtn = document.getElementById('modal-cancel-btn');


            editor.on('change', function() {
                if (!isDirty) {
                    isDirty = true;
                    saveBtn.innerText = i18n.save_changes_btn;
                    saveBtn.className = 'btn-save-dirty'; 
                    reloadBtn.disabled = false;
                    draftDot.className = 'status-dot dot-orange';
                }
            });
            
            window.onbeforeunload = function() {
                if (isDirty) {
                    return i18n.unsaved_changes_alert;
                }
            };
            
            editorForm.addEventListener('submit', function() {
                editor.save(); // Ensure the textarea is updated before submitting
                window.onbeforeunload = null;
            });

            reloadBtn.addEventListener('click', function() {
                if (isDirty) {
                    if (confirm(i18n.reload_draft_confirm)) {
                        window.onbeforeunload = null;
                        window.location.reload();
                    }
                }
            });

            wordWrapToggle.addEventListener('change', function() {
                editor.setOption('lineWrapping', this.checked);
            });

            if (viewDraftLink) {
                viewDraftLink.addEventListener('click', function(event) {
                    if (isDirty) {
                        event.preventDefault(); 
                        // Populate modal with translated text
                        modalTitle.innerText = i18n.modal_title;
                        modalText.innerText = i18n.modal_text;
                        modalSaveBtn.innerText = i18n.modal_save_view;
                        modalViewSavedBtn.innerText = i18n.modal_view_saved;
                        modalCancelBtn.innerText = i18n.modal_cancel;
                        modal.style.display = 'flex';
                    }
                });
            }

            // Custom Modal Logic
            modalSaveBtn.addEventListener('click', function() {
                modal.style.display = 'none';
                saveBtn.click(); // Trigger the main save button
            });

            modalViewSavedBtn.addEventListener('click', function() {
                 modal.style.display = 'none';
                 window.open(viewDraftLink.href, '_blank');
            });

            modalCancelBtn.addEventListener('click', function() {
                 modal.style.display = 'none';
            });
            
            // Close modal if clicking on the overlay
             window.onclick = function(event) {
                if (event.target == modal) {
                    modal.style.display = "none";
                }
            }
        });
    </script>
<?php endif; ?>

</div>
</body>
</html>

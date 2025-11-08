#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use LWP::UserAgent;
use HTML::TreeBuilder;
use File::Slurp qw(read_file write_file);
use Data::Dumper;
use DateTime;

# Configurazione
my $URL = 'https://liceotouschek.synapsy.it/site1/index.php?at=33552';
my $STATE_FILE = 'circolari_state.txt';
my $LOG_FILE = 'circolari_monitor.log';
my $CHECK_INTERVAL = 3600; # Controlla ogni ora (in secondi)

# Opzioni da riga di comando
my $NO_MAIL = 0;  # Impostato da --no-mail

# Configurazione Email
my $EMAIL_ENABLED = 1;  # 1 = attivo, 0 = disattivo
my $EMAIL_TO = 'target@example.com,another@example.com';  # Puoi usare più email separate da virgola o spazio
my $EMAIL_FROM = 'webmaster@example.com';  # Configurato in ~/.msmtprc
my $EMAIL_SUBJECT = 'Nuove Circolari - Liceo Touschek';
my $SENDMAIL = '/usr/bin/msmtp';  # Usa msmtp

# Funzione per loggare messaggi
sub log_message {
    my ($msg) = @_;
    my $timestamp = DateTime->now->strftime('%Y-%m-%d %H:%M:%S');
    my $log_entry = "[$timestamp] $msg\n";
    
    # Output su console
    binmode STDOUT, ':utf8';
    print $log_entry;
    
    # Scrivi su file
    open my $fh, '>>', $LOG_FILE or die "Impossibile aprire $LOG_FILE: $!";
    binmode $fh, ':utf8';
    print $fh $log_entry;
    close $fh;
}

# Funzione per scaricare e parsare la pagina
sub get_circolari {
    my $ua = LWP::UserAgent->new(
        agent => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36',
        timeout => 30,
    );
    
    log_message("Scaricamento pagina da $URL...");
    my $response = $ua->get($URL);
    
    unless ($response->is_success) {
        log_message("ERRORE: Impossibile scaricare la pagina: " . $response->status_line);
        return;
    }
    
    my $content = $response->decoded_content;
    
    # Parse HTML
    my $tree = HTML::TreeBuilder->new_from_content($content);
    my %circolari;
    
    # Cerca il contenitore principale delle circolari (div con id="textbox2")
    # Questo è il contenitore che contiene tutte le circolari nella pagina
    my $textbox = $tree->look_down(_tag => 'div', id => 'textbox2');
    
    if ($textbox) {
        # Cerca tutti i link alle circolari dentro questo contenitore
        # La struttura HTML è regolare: tutti i link a viewdoc.php?id= dentro
        # questo div sono circolari, indipendentemente dal testo del titolo
        for my $link ($textbox->look_down(_tag => 'a', href => qr/viewdoc\.php\?id=/)) {
            my $href = $link->attr('href');
            my $title = $link->attr('title') || '';
            my $text = $link->as_text || '';
            
            # Estrai l'ID della circolare
            if ($href =~ /id=(\d+)/) {
                my $id = $1;
                my $circolare_text = $title || $text;
                $circolare_text =~ s/^\s+|\s+$//g; # Trim whitespace
                
                # Tutti i link a viewdoc.php?id= dentro il contenitore delle circolari
                # sono considerati circolari, senza filtri sul testo
                $circolari{$id} = {
                    id => $id,
                    title => $circolare_text,
                    url => ($href =~ /^http/ ? $href : "https://liceotouschek.edu.it$href"),
                };
            }
        }
    } else {
        # Fallback: se non troviamo il contenitore specifico, cerchiamo tutti i link
        # (per compatibilità con eventuali cambiamenti nella struttura HTML)
        log_message("ATTENZIONE: contenitore textbox2 non trovato, uso metodo fallback");
        for my $link ($tree->look_down(_tag => 'a', href => qr/viewdoc\.php\?id=/)) {
            my $href = $link->attr('href');
            my $title = $link->attr('title') || '';
            my $text = $link->as_text || '';
            
            if ($href =~ /id=(\d+)/) {
                my $id = $1;
                my $circolare_text = $title || $text;
                $circolare_text =~ s/^\s+|\s+$//g;
                
                $circolari{$id} = {
                    id => $id,
                    title => $circolare_text,
                    url => ($href =~ /^http/ ? $href : "https://liceotouschek.edu.it$href"),
                };
            }
        }
    }
    
    $tree->delete;
    
    log_message("Trovate " . scalar(keys %circolari) . " circolari");
    return \%circolari;
}

# Funzione per caricare lo stato precedente
sub load_state {
    return {} unless -e $STATE_FILE;
    
    my $content = read_file($STATE_FILE, binmode => ':utf8');
    my %state;
    
    for my $line (split /\n/, $content) {
        next unless $line =~ /^(\d+)\|(.+)$/;
        $state{$1} = $2;
    }
    
    return \%state;
}

# Funzione per salvare lo stato corrente
sub save_state {
    my ($circolari) = @_;
    
    my @lines;
    for my $id (sort { $b <=> $a } keys %$circolari) {
        push @lines, "$id|" . $circolari->{$id}{title};
    }
    
    write_file($STATE_FILE, {binmode => ':utf8'}, join("\n", @lines) . "\n");
}

# Funzione per inviare email
sub send_email {
    my ($new_circolari, $all_circolari) = @_;
    
    return unless $EMAIL_ENABLED;
    return unless $EMAIL_TO;
    
    my $count = scalar @$new_circolari;
    
    # Costruisci il corpo dell'email - PARTE 1: Nuove circolari
    my $body = "Sono state pubblicate $count nuove circolari sul sito del Liceo Touschek:\n\n";
    
    # Crea un hash con gli ID delle nuove circolari già mostrate
    my %new_ids;
    for my $circ (@$new_circolari) {
        $new_ids{$circ->{id}} = 1;
        $body .= "• " . $circ->{title} . "\n";
        $body .= "  Link: " . $circ->{url} . "\n\n";
    }
    
    # PARTE 2: Ultime 10 circolari pubblicate (escludendo quelle già mostrate)
    $body .= "\n" . "="x70 . "\n";
    $body .= "ULTERIORI 10 CIRCOLARI PUBBLICATE\n";
    $body .= "="x70 . "\n\n";
    
    # Ordina tutte le circolari per ID (dal più recente al più vecchio)
    my @all_sorted = sort { $b->{id} <=> $a->{id} } values %$all_circolari;
    
    # Filtra escludendo quelle già mostrate nel primo gruppo
    my @filtered = grep { !exists $new_ids{$_->{id}} } @all_sorted;
    
    # Prendi le prime 10 (escludendo quelle già mostrate)
    my @last_10 = splice @filtered, 0, 10;
    
    for my $circ (@last_10) {
        $body .= "• " . $circ->{title} . "\n";
        $body .= "  Link: " . $circ->{url} . "\n\n";
    }
    
    $body .= "\n";
    $body .= "Questo è un messaggio automatico del sistema di monitoraggio circolari.\n";
    $body .= "Pagina circolari: $URL\n";
    
    # Parse destinatari (supporta virgole e spazi)
    my @recipients = split /[,\s]+/, $EMAIL_TO;
    @recipients = grep { $_ } @recipients;  # Rimuovi stringhe vuote
    
    # Se --no-mail è attivo, non inviare ma solo loggare
    if ($NO_MAIL) {
        log_message("--no-mail attivo: email NON inviata (debug mode)");
        log_message("Destinatari: " . join(', ', @recipients));
        log_message("Contenuto email:\n$body");
        return;
    }
    
    return unless -x $SENDMAIL;
    
    # Invia email usando sendmail/msmtp
    eval {
        open my $mail, '|-', $SENDMAIL, '-a', 'default', @recipients or die "Impossibile aprire sendmail: $!";
        binmode $mail, ':utf8';
        print $mail "Subject: $EMAIL_SUBJECT ($count nuove)\n";
        print $mail "Content-Type: text/plain; charset=UTF-8\n";
        print $mail "\n";
        print $mail $body;
        close $mail;
        
        log_message("Email inviata a: " . join(', ', @recipients));
    };
    
    if ($@) {
        log_message("ERRORE invio email: $@");
    }
}

# Funzione per inviare notifica
sub notify {
    my ($new_circolari, $all_circolari) = @_;
    
    my $count = scalar @$new_circolari;
    my $msg = "\n" . "="x70 . "\n";
    $msg .= "🔔 NUOVE CIRCOLARI PUBBLICATE ($count)\n";
    $msg .= "="x70 . "\n\n";
    
    for my $circ (@$new_circolari) {
        $msg .= "📄 " . $circ->{title} . "\n";
        $msg .= "   🔗 " . $circ->{url} . "\n\n";
    }
    
    $msg .= "="x70 . "\n";
    
    log_message($msg);
    
    # Invia email se configurato
    send_email($new_circolari, $all_circolari);
}

# Funzione per mostrare l'help
sub show_help {
    print <<HELP;
Monitor Circolari Liceo Touschek

USAGE:
    $0 [OPZIONI]

OPZIONI:
    --init      Inizializza lo stato senza notificare (primo avvio)
    --once      Esegue un singolo controllo ed esce
    --loop      Esecuzione continua (loop infinito)
    --no-mail   Disabilita l'invio email (solo log, utile per debug)
    --help      Mostra questo messaggio di aiuto

ESEMPI:
    # Prima esecuzione (inizializza senza notificare)
    $0 --init
    
    # Controllo singolo
    $0 --once
    
    # Controllo singolo senza invio email (debug)
    $0 --once --no-mail
    
    # Esecuzione continua (loop)
    $0 --loop
    
    # Esecuzione continua in background
    nohup $0 --loop > /dev/null 2>&1 &

FILE:
    circolari_state.txt     - File di stato con le circolari già viste
    circolari_monitor.log   - File di log delle attività

HELP
    exit 0;
}

# Funzione principale di controllo
sub check_for_updates {
    my $old_state = load_state();
    my $circolari = get_circolari();
    
    return unless $circolari;
    
    # Trova nuove circolari
    my @new_circolari;
    for my $id (keys %$circolari) {
        unless (exists $old_state->{$id}) {
            push @new_circolari, $circolari->{$id};
        }
    }
    
    if (@new_circolari) {
        # Ordina per ID (dal più recente al più vecchio)
        @new_circolari = sort { $b->{id} <=> $a->{id} } @new_circolari;
        notify(\@new_circolari, $circolari);
    } else {
        log_message("Nessuna nuova circolare trovata");
    }
    
    # Salva lo stato aggiornato
    save_state($circolari);
}

# Main
sub main {
    # Parse opzioni da riga di comando
    my @args = @ARGV;
    my $has_action = 0;  # Flag per verificare se c'è un'azione specifica
    
    for my $arg (@args) {
        if ($arg eq '--no-mail') {
            $NO_MAIL = 1;
            log_message("Modalità --no-mail attiva: email disabilitate");
        }
        elsif ($arg eq '--help' || $arg eq '-h') {
            show_help();
        }
        elsif ($arg eq '--init' || $arg eq '--once' || $arg eq '--loop') {
            $has_action = 1;
        }
    }
    
    # Se non ci sono azioni specificate, mostra help
    unless ($has_action) {
        show_help();
    }
    
    # Rimuovi --no-mail dagli argomenti per il parsing successivo
    @ARGV = grep { $_ ne '--no-mail' && $_ ne '--help' && $_ ne '-h' } @ARGV;
    
    log_message("=" x 70);
    log_message("Monitor Circolari Liceo Touschek - Avvio");
    log_message("=" x 70);
    log_message("URL: $URL");
    log_message("Intervallo di controllo: $CHECK_INTERVAL secondi");
    
    # Se è il primo avvio, inizializza lo stato senza notificare
    unless (-e $STATE_FILE) {
        log_message("Primo avvio - inizializzazione stato...");
        my $circolari = get_circolari();
        save_state($circolari) if $circolari;
        log_message("Stato iniziale salvato. Le nuove circolari saranno notificate dal prossimo controllo.");
        return if $ARGV[0] && $ARGV[0] eq '--init';
    }
    
    # Modalità init
    if ($ARGV[0] && $ARGV[0] eq '--init') {
        log_message("Modalità --init: stato già inizializzato");
        return;
    }
    
    # Modalità single-check
    if ($ARGV[0] && $ARGV[0] eq '--once') {
        check_for_updates();
        return;
    }
    
    # Modalità loop continuo
    if ($ARGV[0] && $ARGV[0] eq '--loop') {
        while (1) {
            eval {
                check_for_updates();
            };
            if ($@) {
                log_message("ERRORE durante il controllo: $@");
            }
            
            log_message("Prossimo controllo tra $CHECK_INTERVAL secondi...\n");
            sleep $CHECK_INTERVAL;
        }
    }
}

main();

__END__

=head1 NAME

monitor_circolari.pl - Monitor per le circolari del Liceo Touschek

=head1 SYNOPSIS

    # Mostra l'help
    ./monitor_circolari.pl
    ./monitor_circolari.pl --help
    
    # Prima esecuzione (inizializza senza notificare)
    ./monitor_circolari.pl --init
    
    # Controllo singolo
    ./monitor_circolari.pl --once
    
    # Controllo singolo senza invio email (debug)
    ./monitor_circolari.pl --once --no-mail
    
    # Esecuzione continua (loop)
    ./monitor_circolari.pl --loop
    
    # Con nohup per esecuzione in background
    nohup ./monitor_circolari.pl --loop > /dev/null 2>&1 &

=head1 DESCRIPTION

Questo script monitora la pagina delle circolari del Liceo Touschek e
notifica quando vengono pubblicate nuove circolari.

=head1 OPTIONS

    --init      Inizializza lo stato senza notificare (primo avvio)
    --once      Esegue un singolo controllo ed esce
    --loop      Esecuzione continua (loop infinito)
    --no-mail   Disabilita l'invio email (solo log, utile per debug)
    --help      Mostra questo messaggio di aiuto

=head1 FILES

    circolari_state.txt     - File di stato con le circolari già viste
    circolari_monitor.log   - File di log delle attività

=head1 AUTHOR

Creato per il monitoraggio delle circolari scolastiche.

=cut


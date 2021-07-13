(set-default-font "Monospace 14")


(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(inverse-video t)
 '(package-selected-packages (quote (tree-sitter magit))))
(require 'bs)
(global-set-key (kbd "C-x C-b") 'bs-show)
(global-set-key (kbd "C-x C-n") 'bs-cycle-next)
(global-set-key (kbd "C-x C-p") 'bs-cycle-previous)




 ;; ========= Set colours ==========

;; Set cursor and mouse-pointer colours
(set-cursor-color "red")
(set-mouse-color "goldenrod")



;; Set region background colour
(set-face-background 'region "tan2")



;; Set emacs background colour
;; (set-background-color "gray")
(set-background-color "lightgreen")
;; (set-background-color "black")


;; Following macro is defined as follow to insert text at current point:
;;
;;    TRACE("<uuid-on-the-fly-generated>");
;;
;; sources and snippets from:
;; https://www.emacswiki.org/emacs/KeyboardMacrosTricks
;; http://www.thegeekstuff.com/2010/07/emacs-macro-tutorial-how-to-record-and-play/
;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Save-Keyboard-Macro.html
;; https://www.emacswiki.org/emacs/ExecuteExternalCommand
;;
;; - start macro record: M-x start-kbd-macro
;; - type text:
;;      TRACE("
;; - command macro: C-u M-! uuidgen 
;; - type text:
;; -    ");
;; - end of macro record: M-x end-kbd-macro
;; - give name to the macro: C-x C-k n
;; - give name "trace" and press enter
;; - dump in elisp : M-x insert-kbd-macro
;; - type "trace" and it will be generated following text:

(fset 'trace
   (lambda (&optional arg) "Keyboard macro." (interactive "p") (kmacro-exec-ring-item (quote ([84 82 65 67 69 40 34 21 134217761 117 117 105 100 103 101 110 return 5 34 41 59] 0 "%d")) arg)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

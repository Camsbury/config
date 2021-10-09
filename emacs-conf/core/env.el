(require 'prelude)

(defgroup cmacs nil
  "the group for my cmacs config"
  :group  'configuration)

(defcustom cmacs-config-path
  (getenv "CONFIG_PATH")
  "path to the cmacs configuration files"
  :type 'string
  :group 'cmacs)

(defcustom cmacs-share-path
  (getenv "SHAREPATH")
  "path to the cmacs configuration files"
  :type 'string
  :group 'cmacs)

(provide 'core/env)

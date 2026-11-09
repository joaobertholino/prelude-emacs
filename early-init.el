;;; early-init.el --- Personal settings before frame creation -*- lexical-binding: t; -*-

;; Accept the window manager's exact pixel size instead of rounding it to
;; character cells, which otherwise changes the size after WM centering.
(setq frame-resize-pixelwise t)

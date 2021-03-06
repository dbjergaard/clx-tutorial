;;;; lterm.lisp

(in-package #:lterm)
(export 'lterm)
;;; "lterm" goes here. Hacks and glory await!

(defun handle-expose-event (count window gcontext)
  (when (zerop count)
    (let* ((width (xlib:drawable-width window))
	   (height (xlib:drawable-height window))
	   (x 0)
	   (y 0)
	   (pixmap (xlib:create-pixmap :width width
				       :height height
				       :depth (xlib:drawable-depth window)
				       :drawable window))
	   (gc-color (xlib:gcontext-foreground gcontext)))
      (xlib:with-gcontext (gcontext :foreground (xlib:gcontext-background gcontext))
	(xlib:draw-rectangle pixmap gcontext 0 0 
			     width height 'fill))
      (loop for j from 0 to 100
      	 do (loop for i from 0 to 100
      	       do (let ((color (xlib:alloc-color (xlib:window-colormap window)
						 (xlib:make-color :red (float (/ i 100)) 
								  :green (float (/ j 100))
								  :blue (float (/ (+ i j) 200))))))
		    (setf (xlib:gcontext-foreground gcontext) color)
		    (xlib:draw-point pixmap gcontext i j))))

    (xlib:copy-area pixmap gcontext 0 0 width height window 0 0)))
  nil)

(defun handle-enter-event (exitp)
  (if exitp
      (format t "Mouse left window! ~%" )
      (format t "Mouse entered window! ~%" )))
(defun constituent(c)
  (and (graphic-char-p c)
       (not (char= c #\space))))
(defun white-space-split (string)
  (when (plusp (length string))
    (let ((cut-point (position-if
		      (complement #'constituent)
		      string)))
      (if cut-point
	  (cons (subseq string 0 cut-point)
		(white-space-split
		 (subseq string (1+ cut-point))))
	(list string)))))

(defun lterm (&optional (host ""))
  (let* ((display (xlib:open-display host))
	 (screen (first (xlib:display-roots display)))
	 (black (xlib:screen-black-pixel screen))
	 (white (xlib:screen-white-pixel screen))
	 (root-window (xlib:screen-root screen))
	 (gcontext (xlib:create-gcontext
		    :drawable root-window
		    :font "-lispm-fixed-medium-r-normal-*-13-*-*-*-*-*-*-*"
		    :foreground white
		    :background black))
	 (window (xlib:create-window
		  :parent root-window
		  :x 0 :y 0
		  :width 500 :height 250
		  :background black
		  :event-mask (xlib:make-event-mask :exposure
						    :button-press
						    :structure-notify)))
	 (width nil)
	 (height nil))
    ;(describe (xlib:gcontext-font gcontext))
    (xlib:map-window window)
    (xlib:event-case (display :force-output-p t
			      :discard-p t)
      (:configure-notify (w-w w-h) (setf width w-w
					 height w-h) nil)
      (:exposure (count) (handle-expose-event count window gcontext))
      (:button-press () t)
      (:destroy-notify () t))
    (xlib:destroy-window window)
    (xlib:close-display display)))

Various |TeX| tools
===================


``fix_synctex.py``
------------------

Unfortunately the very useful |SyncTeX| extension doesn’t work if the output
directory is different from the input directory (|ie|, when the
``--output-directory`` has been specified at compilation time).  To work around
this limitation, the ``fix_synctex.py`` script (which requires Python 3) prepends the path of the input directory (by default the current directory) to all relative input paths found in the |SyncTeX| information file.  Use like::

    fix_synctex.py dir1/test1.synctex dir2/test2.synctex.gz


.. role:: raw-html(raw)
   :format: html

.. role:: raw-latex(raw)
   :format: latex

.. |ie| replace:: *i. e.*
.. |TeX| replace:: :raw-latex:`\TeX`:raw-html:`TeX`
.. |SyncTeX| replace:: :raw-latex:`Sync\TeX`:raw-html:`SyncTeX`

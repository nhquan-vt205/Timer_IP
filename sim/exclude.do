# Coverage exclusions, written by excl_save (cov_excl.tcl).
# Edit the exclusions in the coverage GUI (make cov_gui), not by hand.
coverage exclude -src ../rtl/apb_slave.v -item 1 -fer 63 3 -comment "apb_acc=0 with pready_q=1: master drops the access in the ready cycle, illegal per AMBA APB" 
coverage exclude -src ../rtl/apb_slave.v -item 1 -fer 64 3 -comment "apb_acc=0 with pready_q=1: master drops the access in the ready cycle, illegal per AMBA APB" 

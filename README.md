# exp_interface

Used to collect the data for [this dataset](https://github.com/jacobWhite717/EEG_data).

### Relevant files
**interface_tutorial.m** was used to briefly teach the participant how the session would work.

**reading_interface.m** was used for the actual session to record data.
* Must set the following when starting a session:
  1. *SUBJECT_NUM* to apropriate participant number.
  2. *serial_port* to the COM port of the trigger box
  3. *pahandle* to the correct audio device 
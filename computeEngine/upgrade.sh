#!/bin/bash

source source_scripts.sh

create_logfile

start_prompt "upgrade"

select_update_type

end_prompt "upgrade"
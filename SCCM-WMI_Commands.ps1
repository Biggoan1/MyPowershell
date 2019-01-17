#Machine Policy Retrieval Cycle
Invoke-WmiMethod -Namespace "Root\CCM" -Class SMS_Client -Name TriggerSchedule -ArgumentList "{00000000-0000-0000-0000-000000000021}"

#Machine Policy Evaluation Cycle
Invoke-WmiMethod -Namespace "Root\CCM" -Class SMS_Client -Name TriggerSchedule -ArgumentList "{00000000-0000-0000-0000-000000000022}"

#Application Deployment Evaluation Cycle
Invoke-WmiMethod -Namespace "Root\CCM" -Class SMS_Client -Name TriggerSchedule -ArgumentList "{00000000-0000-0000-0000-000000000121}"


<#
https://www.systemcenterdudes.com/configuration-manager-2012-client-command-list
https://rid500.wordpress.com/2017/07/23/sccm-refresh-machine-policy-retrieval-evaluation-cycle-via-wmi

Application Deployment Evaluation Cycle	"{00000000-0000-0000-0000-000000000121}"
Discovery Data Collection Cycle	"{00000000-0000-0000-0000-000000000003}"
File Collection Cycle "{00000000-0000-0000-0000-000000000010}"
Hardware Inventory Cycle "{00000000-0000-0000-0000-000000000001}"
Machine Policy Retrieval Cycle "{00000000-0000-0000-0000-000000000021}"
Machine Policy Evaluation Cycle	"{00000000-0000-0000-0000-000000000022}"
Software Inventory Cycle "{00000000-0000-0000-0000-000000000002}"
Software Metering Usage Report Cycle "{00000000-0000-0000-0000-000000000031}"
Software Updates Assignments Evaluation Cycle "{00000000-0000-0000-0000-000000000108}"
Software Update Scan Cycle "{00000000-0000-0000-0000-000000000113}"
State Message Refresh "{00000000-0000-0000-0000-000000000111}"
User Policy Retrieval Cycle "{00000000-0000-0000-0000-000000000026}"
User Policy Evaluation Cycle "{00000000-0000-0000-0000-000000000027}"
Windows Installers Source List Update Cycle "{00000000-0000-0000-0000-000000000032}"

#>
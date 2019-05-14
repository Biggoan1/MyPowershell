
Get-wmiobject –namespace root\ccm\clientsdk –class ccm_program | select packageid,fullname,evaluationstate | where {$_.evaluationstate –ne 1}


 $c=(gwmi -Namespace root\ccm\SoftMgmtAgent -Class CCM_TSExecutionRequest -Filter “State = ‘Completed’ And CompletionState = ‘Failure'”); if ($c) {$c.Delete(); Restart-Service ccmexec -force}


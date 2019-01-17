<#
.SYNOPSIS
Compair SCCM Content Lib vs WMI Package List

.DESCRIPTION
Compair SCCM Content Lib vs WMI Package List

.EXAMPLE
.PARAMETER 
.NOTES
1.0 Initial Release 

#>

# WMI Package Info
$WMIPkgList = Get-WmiObject -Namespace Root\SCCMDP -Class SMS_PackagesInContLib | Select -ExpandProperty PackageID | Sort-Object

# SCCM Content Lib Info
$ContentLib = (Get-ItemProperty -path HKLM:SOFTWARE\Microsoft\SMS\DP -Name ContentLibraryPath)
$PkgLibPath = ($ContentLib.ContentLibraryPath) + "\PkgLib"
$PkgLibList = (Get-ChildItem $PkgLibPath | Select -ExpandProperty Name | Sort-Object)
$PkgLibList = ($PKgLibList | ForEach-Object {$_.replace(".INI","")})

# Compare Lib vs WMI
$PksinWMIButNotContentLib = Compare-Object -ReferenceObject $WMIPkgList -DifferenceObject $PKgLibList -PassThru | Where-Object { $_.SideIndicator -eq "<=" } 
$PksinContentLibButNotWMI = Compare-Object -ReferenceObject $WMIPkgList -DifferenceObject $PKgLibList -PassThru | Where-Object { $_.SideIndicator -eq "=>" } 

Write-Host Items in WMI but not the Content Library
Write-Host ========================================
$PksinWMIButNotContentLib

Write-Host Items in Content Library but not WMI
Write-Host ====================================
$PksinContentLibButNotWMI

<#
# Remove WMI Items
Foreach ($Pkg in $PksinWMIButNotContentLib) 
    {
        Get-WmiObject -Namespace Root\SCCMDP -Class SMS_PackagesInContLib -Filter "PackageID = '$Pkg'" | Remove-WmiObject
    }

# Remove from Content Lib
Foreach ($Pkg in $PksinContentLibButNotWMI)
    {
        Remove-Item -Path "$PkgLibPath\$Pkg.INI"
    }


CE1001DD
CE1001DE
CE1001DF
CE1001E0
CE1001E1
CE1001E2
CE1001E3
CE1001EA
CE1001EF
CE1001F0
CE1001F4
CE1001F5
CE100203
CE10021A
CE100225
CE100237
CE100238
CE100239
CE100240
CE100273
LAB000F3
PS10006B
PS1000E3
PS10010B
PS1001B9
PS1002A3
PS1002DC
PS10032F
PS100355
PS100660
PS100685
PS1007C9
PS1007FA
PS10081C
PS10085C
PS10085D
PS100884
PS1008C5
PS1008CA
PS1008CE
PS1008CF
PS10096A
PS100A3E
PS100ABE
PS100AE1





CE100088
CE1001DD
CE1001DE
CE1001DF
CE1001E0
CE1001E1
CE1001E2
CE1001E3
CE1001EA
CE1001EF
CE1001F0
CE1001F4
CE1001F5
CE100203
CE10021A
CE100225
CE100237
CE100238
CE100239
CE100240
CE10025F
CE100273
CE1002C3
CE1002C4
CE100300
CE1003AE
CE1003AF
CE1003B1
CE1003B2
CE1003B3
CE1003DE
CE10040F
CE100478
CE1004BC
CE1004CC
CE1004F2
CE1004FB
CE100519
CE100543
CE10058C
CE100590
CE1006A1
PS10006B
PS1001B9
PS10085C
PS10085D
PS100875
PS1008CA
PS1008CE
PS1008CF
PS10096A
PS100A3E


CE1000C9
CE1000D3
CE10011E
CE100120
CE100121
CE100123
CE10013F
CE100145
CE10014D
CE100174
CE10017F
CE100185
CE10019F
CE1001A2
CE1001A4
CE1001C7
CE1001CC
CE1001D5
CE100222
CE100233
CE100248
CE10026C
CE100271
CE100274
CE10027B
CE10027D
CE10028E
CE10028F
CE100290
CE100293
CE100296
CE100298
CE10029D
CE10029E
CE1002A5
CE1002BE
CE1002DC
CE1002E6
CE1002E8
CE1002EC
CE1002F5
CE1002F6
CE1002FD
CE100311
CE100349
CE100362
CE1003D5
CE1003D7
CE1003F8
CE10042C
CE100443
CE10044C
CE10044E
CE10046C
CE10048B
CE100491
CE100496
CE1004CF
CE1004F1
CE1004F3
CE100538
CE10053C
CE100563
CE10057A
CE100591
CE10059A
CE1005AB
CE1005CB
CE1005E4
CE100606
CE10060C
CE10060E
CE100626
CE10064B
CE10064C
CE100661
CE100670
CE100684
CE10068C
CE10068E
CE100693
CE1006E0
CE1006E1
CE1006F6
CE1006F9
LAB00045
LAB0006A
LAB00072
LAB00079
LAB0007C
LAB0008A
LAB00096
LAB000AF
LAB000B6
LAB000B7
LAB000C8
LAB000D8
LAB000DC
LAB000DD
LAB000EC
LAB00108
LAB00111
LAB00112
LAB00114
LAB00115
LAB00116
LAB00117
LAB00118
LAB0011D
LAB0011E
LAB0011F
LAB00120
LAB00121
LAB00122
LAB00124
LAB00136
LAB00137
LAB00142
LAB00143
LAB00144
LAB00156
LAB00157
LAB00159
LAB0015B
PS10001A
PS100027
PS10002D
PS10004B
PS10004E
PS10004F
PS100053
PS100058
PS10005A
PS10005B
PS1000A0
PS1000AA
PS1000AB
PS1000AC
PS1000AE
PS1000AF
PS1000BA
PS1000BB
PS1000D7
PS1000DA
PS1000DC
PS1000DD
PS1000E2
PS1000E7
PS1000E8
PS1000E9
PS1000EA
PS1000EB
PS1000ED
PS1000F9
PS10010C
PS10010D
PS10010E
PS100119
PS10011D
PS100122
PS100125
PS100129
PS10012C
PS10012F
PS100130
PS100132
PS100141
PS10014E
PS100151
PS10015F
PS100170
PS100172
PS100179
PS10017C
PS100183
PS100196
PS10019C
PS1001AE
PS1001B0
PS1001B1
PS1001B2
PS1001B6
PS1001B7
PS1001B8
PS1001BC
PS1001BD
PS1001BF
PS1001C0
PS1001C4
PS1001C8
PS1001CE
PS100246
PS100250
PS10027B
PS10027D
PS1002B2
PS1002CF
PS1002D0
PS1002D3
PS1002DD
PS1002DE
PS1002E5
PS1002ED
PS1002F0
PS1002FB
PS1002FC
PS10030A
PS10030B
PS10030D
PS100316
PS10031D
PS100330
PS100336
PS100337
PS10033A
PS100352
PS100353
PS100354
PS1003D1
PS1003F4
PS100411
PS100412
PS10041B
PS100421
PS10045E
PS10045F
PS100460
PS100482
PS1004A3
PS1004DA
PS1004DF
PS1004FF
PS100522
PS100534
PS1005AC
PS1005B3
PS1005BC
PS1005BD
PS1005BE
PS1005C0
PS1005C2
PS1005C5
PS1005C7
PS1005CB
PS1005CC
PS1005CD
PS1005D1
PS1005E4
PS1005ED
PS1005F0
PS100625
PS100626
PS100628
PS10062E
PS100633
PS100658
PS10065F
PS100669
PS100676
PS10068F
PS1006A0
PS1006A3
PS1006A4
PS1006B1
PS1006B3
PS1006BD
PS1006C0
PS1006C1
PS1006C2
PS1006C3
PS1006F6
PS100700
PS100719
PS100735
PS100759
PS10075B
PS10075C
PS100762
PS100763
PS100764
PS100782
PS10079D
PS1007D1
PS1007E1
PS1007E2
PS1007E3
PS1007E5
PS1007ED
PS100816
PS10081E
PS100820
PS100827
PS10082A
PS10082C
PS100839
PS10083D
PS100855
PS10086A
PS10086D
PS100877
PS100879
PS100880
PS100885
PS10088C
PS10088E
PS1008A3
PS1008AC
PS1008B0
PS1008D3
PS1008D6
PS1008D7
PS1008E7
PS1008E8
PS1008E9
PS1008F2
PS100902
PS100903
PS100904
PS100907
PS10090B
PS100937
PS100943
PS10094B
PS10094E
PS100950
PS100963
PS100964
PS100967
PS10096C
PS10096D
PS100973
PS10097D
PS100985
PS10099A
PS1009AE
PS1009C1
PS1009C6
PS1009CF
PS1009D8
PS1009DD
PS1009E0
PS1009E1
PS1009E2
PS1009E3
PS1009E6
PS1009ED
PS1009F6
PS100A2D
PS100A2E
PS100A2F
PS100A43
PS100A45
PS100A5E
PS100A60
PS100A7B
PS100A7D
PS100A81
PS100A8C
PS100A9C
PS100AAC
PS100AB6
PS100ABA
PS100AC4
PS100AC8
PS100AD5
PS100AD6
PS100AE5
PS100AE7
PS100AFD
PS100AFF
PS100B35
PS100B36
PS100B42
PS100B43
PS100B44
PS100B47
PS100B4B
PS100B5D
PS100B5E
PS100B60
PS100B63
PS100B79
PS100B7D
PS100B8B
PS100B91
PS100B92
PS100B94
PS100B9E
PS100BAD
PS100BEC
PS100BF2
PS100BF5
PS100BFE
PS100C0B
PS100C11
PS100C13
PS100C1E
PS100C21
PS100C26
PS100C2B
PS100C2C
PS100C2D
PS100C2F
PS100C30
PS100C3B
PS100C40
PS100C58
PS100C5C
PS100C65
PS100C66
PS100C6E
PS100C6F
PS100C70
PS100C83
PS100C8F
PS100C9D
PS100CA6
PS100CAD
PS100CAE
PS100CCB
PS100D12
PS100D55
PS100D58
PS100D68
PS100D69
PS100D73
PS100D7A
PS100E1F






#>
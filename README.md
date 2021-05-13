# Check-4VExam

*@version 0.5*

*@author: Ander F.L. for Cuatrovientos ITC*

**Checks computers connection to LAN network.**

This script is used to detect students disconected from organizational network
during an exam. The aim of the script is to avoid the use of mobile phone access points during exams.


Administrative permissions will be need to enable the execution of powershell scripts
 * Powershell scripts checks connection to a list of computers defined in a CSV file by executing PING command.
    - CSV files are stored in etc/ folder with NAME; IP format.
 * To avoid ICMP packages to be blocked by firewall NMap Ping is used 
    - If NMap is not detected in its default installation path, the installation will automatically start.
 * A log file is generated under log/ directory where every executions information will be stored



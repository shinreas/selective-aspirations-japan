* MASTER FILE FOR Gendered Aspirations for Selective University in Japan
* Shinrea Su

clear all

global filepath "C:/Users/sushi/Downloads/25-26/JIW revise"

* Packages
//ssc install vreverse
ssc install cem
ssc install sdid
ssc install sdid_event
ssc install grc1leg2 

cd "$filepath"

* Open, clean, and reshape data
do "do-files/cleaning.do"

* Run regressions and create tables
do "do-files/analysis.do"
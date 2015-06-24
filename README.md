# Talentsaver
With this World of Warcraft AddOn you can save your current Talent Specs and if you have to reset to switch to another spec you can easily let the AddOn load the saved template.


# Changelog
1.3 (27. July 2014)
- added the 'stop' command
- completely remade the BUILD Variables and therefor saving&loading procedures
- fixed the loading procedure if points are already spent

1.2 (26. July 2014)
- changed the Spec Info Variables from string to table with 4 int values(!)
- deleting a spec will now completeley remove it from the LIST table and therefor the /list command
- on loading it will display an estimated loading time
- on loading it will now check how many points you have free and how much you need
--> it can now continue loading the template if you've already spent a few of the needed points correctly
(if you've spent them on your own or the loading process got stopped due to dc)

1.1 (22. July 2014)
- fixed the delay variable (from s to ms)

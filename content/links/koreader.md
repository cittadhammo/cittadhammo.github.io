---
Title: Koreader
parent: Links
---

have a look at <https://koreader.rocks/>

and <https://github.com/koreader/koreader/wiki/Installation-on-Kobo-devices>

You will find a list of kobo model that are suitable. I believe all of them.

You just need to put a script file int he good place I believe, pretty simple instruction.

Also, consider : <https://github.com/olup/kobowriter> for using a keyboard with it, I believe the new model have bluetooth so it might be even easier.

reading <https://github.com/koreader/koreader/wiki/Installation-on-Kobo-devices>:

> Which Kobo Devices?\
> The full Kobo lineup is currently supported, starting from the Touch.\
> While the Clara 2E is supported, it exhibits severe stability issues that are entirely out of our control (i.e., screen refreshes may crash the kernel, causing a hang, followed or not by an automated watchdog-triggered reboot). This is a known issue affecting the board/kernel used by this device. Given that the Libra 2 and Nia run on very similar boards, caution is advised with those two, too.

Knowing that, you can purchase other model than Clara 2E, Libra 2, Nia. I would go for a refurbished one <https://www.kobo.com/gb/en/ereaders>.

For install, you should follow :

> Semi-Automated Installation Method:\
> Refer to the dedicated forum thread, in particular the second post, which provides a script to automate the process, including dealing with the FW 4.17+ quirk mentioned above.\
> This bundles both KFMon and NickelMenu, and should be the most logical choice for brand new users (with no other launcher currently installed on their device).

This means (going on [this forum](https://www.mobileread.com/forums/showthread.php?t=314220)) reading the second message. It will depend on your operating system. I assume you have a windows machine, then:

1.  downlad [this](https://storage.gra.cloud.ovh.net/v1/AUTH_2ac4bfee353948ec8ea7fd1710574097/kfmon-pub/OCP-KOReader-v2023.08.zip) named **OCP-KOReader-v2023.08.zip**
2.  download raw file [here](https://github.com/NiLuJe/kfmon/blob/master/tools/install.ps1) named **install.ps1 **(the download button is under the "last year" on the right)
3.  plug your kobo
4.  On recent Windows versions (i.e., when running PowerShell >= 7), you'll have to "unblock" the script to allow it to run. (Right Click > Tick Unblock in the bottom-right corner).
5.  Run the install.ps1 script with PowerShell (Right Click > Run with PowerShell).
6.  Follow the on-screen instructions.
7.  Safely eject your Kobo, watch it process & reboot

If you go on the forum, you will find the screenshot for windows. It looks much easier on linux or mac. You will need admin priviledge to run the script I imagine.

I can share with you the sutta files and pali dictionnary at a later point. You will be able to install them at any time when you have a ereader with a working koreader install.

You will be able to find a lot of free content here to start <https://readingfaithfully.org/> and <https://suttacentral.net/editions?lang=en>

I am afraid the wisdom publication books are only available for money: <https://wisdomexperience.org/product/middle-length-discourses-buddha/> 40$ for the middle length discourse. But you can get some partial content for free in a legit way it seems: <https://readingfaithfully.org/canonical-collections-for-practice/> The long discourse are free it looks.

The PTS Dict is free and can be downloaded here <https://vpnry.github.io/ptsped/> (scroll down to** Pāḷi Roman (~2.4M) PTSPED-2021.zip Easy copy link: <https://vpnry.github.io/ptsped/stardict/PTSPED-2021.zip>)**

**\
**

For the Pali sutta in pali you have this page <https://readingfaithfully.org/pali-language-ebooks-kindle-and-epub/> I have more file that I can share if needed as well.

To install the dict. on the kobo, follow the instruction here <https://github.com/koreader/koreader/wiki/Dictionary-support>

> *How to install a dictionary\
> To use the dictionary lookup function, you first need to install one or more dictionaries in the StarDict format.\
> The StarDict format dictionary files have suffixes *.idx, *.ifo or *.ifo.gz, *.dict or *.[dict.dz](http://dict.dz/).\
> The dictionaries need to be installed into one of those directories:\
> .adds/koreader/data/dict/ directory for Kobo*

>

This is a hidden folder. Start with a dot. Check how to show hidden folder on you computer (use google) to add the dict files.

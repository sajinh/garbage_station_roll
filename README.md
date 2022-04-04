# garbage_station_roll

**Important Note**

If you do not have a Linux computer, use these programs in the linux
servers provided by the university.

## Preparing the roll

This is an automated system for deciding which residents of
the faculty housing should manage the garbage station. It looks at
a file-based (stored in yaml format) database of past duties for
this purpose.

You need two things to prepare the roll:

1. A collection of `*.yml files` that tells the software about 
which residents managed the station in the past year(s) or past months.


2. The software program `roll.rb`

3. A regularly updated list `mm.yml` containing the relevant details
of the faculty housing apartments and residents.  This should be
kept updated regularly.

The program is run every month as follows:

`ruby roll.rb <month> [year]`

Here <month> is an integer specifying the month for which the roll should
be made. It is a required argument.

[year] is optional, and is an integer specifying the year.

It is recommended to use both arguments. For example, to prepare
a roll for May 2022, use the program as follows:

`ruby roll.rb 5 2022`

## Sending the mail

Preparing the email to be sent to residents can similarly be automated. 
Please use the program `prepare_mail.rb` for this.

You need to prepare a few things for this to work smoothly:

1. Use a computer at the university which is connected to the
   university intranet. It should have access to the mail server.

2.  Save your password in encrypted format in a protected folder
  somewhere in your computer. If you do not have linux on your
  computer, use these programs in the servers provided by the
  university. See method `get_passwd` defined in line 61 of `prepare_mail.rb`
  and make sure the encrypted password is decrypted properly.

3. Edit line 66 of `prepare_mail.rb` to add the fully qualified name of your mail server.
3. Edit line 68 of `prepare_mail.rb` to add the domain of your server.
3. Edit line 69 of `prepare_mail.rb` to add the correct the user name.

4. Edit line 81 of `prepare_mail.rb` to add the correct email address of
   the sender.

4. Edit lines 82,83,84,85 to add the email addresses of the groups
   to whom the mail should be sent.

5. Make sure lines 88 and 89 point to the correct attachments.

6. Edit body.txt.erb as needed. Please see lines 6, 65, and 67
   especially.

The program `prepare_mail.rb` can be run every month as follows:

`ruby prepare_mail.rb <month> [year]`

Here <month> is an integer specifying the month for which the mail should
be sent. It is a required argument.

[year] is optional, and is an integer specifying the year.

It is recommended to use both arguments. For example, to prepare
and send the mail roll for May 2022, use the program as follows:

`ruby prepare_mail.rb 5 2022`

Once the programs are seen to work fine, one could use the crontab
facility to automate both processes so that both the preparation
of the roll, and the sending of emails do not need manual work.


use inc::Module::Install;

name            ('Kwiki-Comments');
abstract        ('Post Comments to Kwiki Pages');
author          ('Kang-min Liu (gugod@gugod.org)');
license         ('perl');
version         ('0.01');
requires        ('Kwiki');
requires	('DBD::SQLite');

&WriteAll;


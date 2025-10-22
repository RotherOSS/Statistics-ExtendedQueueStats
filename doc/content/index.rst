.. toctree::
    :maxdepth: 2
    :caption: Contents

Sacrifice to Sphinx
===================

Description
===========
This module contains additional statistic modules for ticket analysis of OTOBO.

System requirements
===================

Framework
---------
OTOBO 10.1.x

Packages
--------
\-

Third-party software
--------------------
\-

Usage
=====

The package provides two additional dynamic statistics and one additional static statistic.

Stats for Queue Resting Time
----------------------------

Using this statistic, it is possible to calculate the resting time of tickets for queues. The statistic considers also the close times of tickets. This accounted time will not be added to the resting time or the resting time based on the working period. The resting time based on working periods will only be displayed if a calendar is configured for the respective queues.

Stats for Queue Working Time
----------------------------

This statistic is a modified ticket list to calculate and display the working time per queue.

It contains three new columns for the X axis. In general, the time for the three new columns is calculated based on the time where the ticket was not in a state of type closed, removed or merged. Examples are:

- ``Queue Misc time`` contains the time the agents have worked on a ticket.
- ``Queue Misc working time`` contains the time the agents have worked on the ticket based on the working calendars of the queue ``Misc``.
- ``Queue Misc effective time`` contains the time the agents set as time units for the ticket while it was in the queue ``Misc``. The values are displayed for each agent by first and last name in the same column (comma-separated).

Stats for Response Statistic
----------------------------

This static type statistic makes it possible to count how many times a response template has been used within a given time frame. The result can be filtered by time period and by queue.

Setup
-----

Configuration Reference
-----------------------

Core::Stats
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

QueueRestingTime::HistorySearchLimit
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
This setting defines a limit for query results on ticket history table for OTOBOStatsQueueRestingTime stat.

Stats::DynamicObjectRegistration###OTOBOStatsQueueRestingTime
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Module to generate statistics about ticket duration of stay in queues.

Stats::DynamicObjectRegistration###OTOBOStatsQueueWorkingTime
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
A modified ticket list statistic to display the working time per queue.

About
=======

Contact
-------
| Rother OSS GmbH
| Email: hello@otobo.io
| Web: https://otobo.io

Version
-------
Author: |doc-vendor| / Version: |doc-version| / Date of release: |doc-datestamp|

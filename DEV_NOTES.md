Dear Jake,

You want to add the functionality to Auditors Webhook so that when an audit
issue is closed and we're set up to listen to audit-closed issues, we close all
the linked audits as well.

This feature can be made optional by simply not configuring the 'issues' webhook
on that GitHub repo.

You refactored your code into `/routes/audits/{opened,closed}.coffee`.

- You left psuedo code comments in for closed.coffee.
- You realized that for opened.coffee has a lot of API calls: and wanted to stop
  and re-architect it. Re-read the function carefully, think about how to add
  the functionality described above, and make the code better.

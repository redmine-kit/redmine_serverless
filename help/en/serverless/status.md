# Status and connections

Administration › Serverless › **Status and connections** shows how Redmine runs on AWS Lambda: the function and its role, the versions, the settings read from SSM Parameter Store (names only, never values), and the Redmine settings that are fixed on Lambda.

**Check the connections** checks the database and each AWS service the installed plugins use, once, and shows **OK** or **Failed** with the detail. Only administrators can open the page.

The Redmine settings fixed on Lambda (fetching repositories automatically, the web services for repositories and incoming email) are shown disabled in Administration › Settings, because they cannot work on Lambda.

More: [Redmine Serverless: administration pages](https://redmine-kit.github.io/redmine_serverless/admin.html).

# Auditors Webhook

Sometimes, the change you've made to a project is too small to make a
full-fledged pull request, but you'd still like a pair of eyes to review it at
some point. This project gives you an option for handling exactly this scenario.
You push your changes, assign someone to "audit" them, and they can take a look
when they get the chance while your changes land immediately.

It works as a simple Express.js app that creates issues to track post-commit
code review requests.

When set up, it uses the GitHub webhooks and issues APIs to create an issue for
each commit that has 'Auditors: ' in the message body at the start of a line.
One issue is created for each auditor and each commit. The auditor is assigned
on the issue, and the corresponding commit to be reviewed is linked in the issue
body.


## Usage

Here's how it looks in real life.

### Write your commit

Once you've followed the [Setup](#setup) instructions below, you can add
auditors to your commits by just adding the line `Auditors: username1 [username1
...]` to your commit messages:

![Auditors in commit message][audit-commit-message]

### Browse the issue

When that commit gets pushed to the repo you configured the webhook for, it
creates an issue that looks like this:

![auditor issue][audit-issue]

You can see that it...

- creates an issue for every auditor on each commit, and assigns auditors to the
  issues
- links to the commit diff, so you can discuss the changes in line
- adds the "audit" label
- mentions the author, so they can see all open audits they're participating in

### Review the commit

When the auditor gets around to it, they can use GitHub's normal commit view to
see your changes. The code review discussion should be on the GitHub page for
that commit (as opposed to on the audit issue):

![auditor commit][audit-commit]

That's it! Follow the setup below to get it working for your repositories.


## Setup

There are two ways to get set up; you can get set up for [The Real
World](#the-real-world) or for [development](#development).

### The Real World

This app can be deployed with Heroku.

```console
$ git clone https://github.com/jez/auditors-webhook
```

Next, either install the [Heroku toolbelt][toolbelt], or make sure you have the
[foreman][foreman] gem installed.

```console
Install the Heroku toolbelt package installer from Heroku

or

$ brew install heroku-toolbelt
$ gem install foreman
```

You'll need to choose a name for your app on Heroku, then create it at the
command line:

```console
$ heroku create <myapp's name>
```

Next up, you'll need to create an __[application on GitHub][gh-app]__
to get an app `client_id` and `client_secret`. Fill in

- "Homepage URL" with <http://MYAPP_NAME.herokuapp.com>
- "Authorization callback URL" with <http://MYAPP_NAME.herokuapp.com/callback>

Replace `MYAPP_NAME` as necessary. Click "Register application". Once you have
a client id and client secret, fill in the appropriate values in `.env.template`
after renaming it to `.env.prod`.

```console
$ cp .env.template .env.prod

(Edit .env.prod)
```

Now push this config to Heroku:

```console
$ heroku config:push -e .env.prod
```

We are now safe to deploy the app to Heroku:

```console
$ git push heroku master
```

We have to create a Webhook on GitHub for the repo you want to enable auditors
on by

1. navigating to your organization or repository settings
1. finding the "Webhooks & Services" tab
1. setting "Payload URL" to `<your "Forwarding" URL>/postreceive`
1. clicking add (the defaults are good for everything else)


We're almost there. Last up, we need to get an access token so we can use the
GitHub API.

> To get the appearance that these commits are being created by a bot, now is
> the time to create a bot account. Use it when signing in below.

1. Go to <http://MYAPP_NAME.herokuapp.com>
1. Click "Login with GitHub"
1. Authorize the application
1. Copy the access token and find the line in `.env.prod` where it needs to go (it
   is commented out by default; uncomment it)
1. Run `heroku config:push -e .env.prod` again

We're also going to want to be able to verify that requests from GitHub are
actually coming from GitHub:

1. Run `ruby -rsecurerandom -e 'puts SecureRandom.hex(20)` and note the output
   (or just come up with some random string).
1. Uncomment `WEBHOOK_SECRET` from `.env` and add this string there.
1. Add this string to the "Secret" field where you configured your repo (it was
   on the "Webhooks & Services" tab on GitHub)
1. Run `heroku config:push -e .env.prod` to sync the config with Heroku


That's it! You should be able to commit to any repo you configured with
`Auditors: <GitHub username>` in the commit message and have issues be created.


### Development

The development environment requires a Node.js development environment.

```console
$ git clone https://github.com/jez/auditors-webhook
$ npm install

# If you want a fancy development environment:
$ npm install -g nodemon
```

Next, either install the [Heroku toolbelt][toolbelt], or make sure you have the
[foreman][foreman] gem installed.

```console
Install the Heroku toolbelt package installer from Heroku

or

$ brew install heroku-toolbelt
$ gem install foreman
```

Next up, you'll need to create an __[application on GitHub][gh-app]__
to get an app `client_id` and `client_secret`. Fill in

- "Homepage URL" with <http://localhost:5000>
- "Authorization callback URL" with <http://localhost:5000/callback>

Click "Register application". Once you have a client id and client secret, fill
in the appropriate values in `.env.template` after renaming it to `.env`.

```console
$ cp .env.template .env

(Edit .env)
```

In development, we'll need a way to expose our localhost app to the Internet so
that GitHub can hit it with it's webhooks. This can be done with [ngrok][ngrok].

```console
$ brew install ngrok
```

`ngrok` works by giving us an arbitrary subdomain on `ngrok.com`. All traffic to
this domain is forwarded to a port on our local computer. Start it with

```console
$ ngrok 5000
```

Take note of the `http` URL that ngrok spits out next to "Forwarding":

```
   grok

   Tunnel Status                 online
   Version                       1.7/1.7
>> Forwarding                    http://6bc3b373.ngrok.com -> 127.0.0.1:3000
   Forwarding                    https://6bc3b373.ngrok.com -> 127.0.0.1:3000
   Web Interface                 127.0.0.1:4040
```

Using this URL, create a Webhook on GitHub for the repo you want to enable
auditors on by

1. navigation to your organization or repository settings
1. finding the "Webhooks & Services" tab
1. setting "Payload URL" to `<your "Forwarding" URL>/postreceive`
1. clicking add (the defaults are good for everything else)


Start the server:

```console
$ foreman start
```

We're almost there. We need to get an access token so we can use the
GitHub API.

> To get the appearance that these commits are being created by a bot, now is
> the time to create a bot account. Use it when signing in below.

1. Go to <http://localhost:5000>
1. Click "Login with GitHub"
1. Authorize the application
1. Copy the access token and find the line in `.env` where it needs to go (it
   is commented out by default; uncomment it)

We're also going to want to be able to verify that requests from GitHub are
actually coming from GitHub:

1. Run `ruby -rsecurerandom -e 'puts SecureRandom.hex(20)` and note the output
   (or just come up with some random string).
1. Uncomment `WEBHOOK_SECRET` from `.env` and add this string there.
1. Add this string to the "Secret" field where you configured your repo (it was
   on the "Webhooks & Services" tab on GitHub)

Restart the server one last time.

That's it! You should be able to commit to any repo you configured with
`Auditors: <GitHub username>` in the commit message and have issues be created.


## Further Notes

It's 2015; you should be using HTTPS. Here are some options:

- If you're working on your laptop, you can [set up stress free HTTPS on OS
  X][osx-https]
- If you have a custom domain name, [Cloudflare will give you free
  HTTPS][cloudflare-https]
- Heroku has some addons for adding HTTPS
- [Let's Encrypt][lets-encrypt-https] will be giving out free certificates [soon][lets-encrypt]!
- StartSSL gives out free [SSL certificates][startssl]


## LICENSE

MIT License. See [LICENSE](LICENSE)


[audit-commit-message]: screenshots/audit-commit-message.png
[audit-issue]: screenshots/audit-issue.png
[audit-commit]: screenshots/audit-commit.png

[gh-app]: https://github.com/settings/developers
[toolbelt]: https://toolbelt.heroku.com/
[foreman]: https://github.com/ddollar/foreman
[ngrok]: https://ngrok.com/

[osx-https]: https://gist.github.com/jed/6147872
[cloudflare-https]: https://www.cloudflare.com/ssl
[lets-encrypt-https]: https://letsencrypt.org/
[lets-encrypt]: https://letsencrypt.org/2015/06/16/lets-encrypt-launch-schedule.html
[startssl]: https://www.startssl.com/

# Auditors Webhook

This is a simple Node.js + Express app that creates issues to be used for
post-commit code review.

When set up, this app uses GitHub webhooks to create an issue for each commit
that has 'Auditors: ' in the message body. One issue is created for each auditor
and each commit. The auditor is assigned on the issue, and the corresponding
commit to be reviewed is linked in the issue body.

## Setup

There is still a little bit of work to be done before this is "production
ready", but that doesn't mean you can't use it now.

### Install dependencies

First up, you'll need to create a Developer Application on GitHub to get an app
`client_id` and `client_secret`. Once you have these, fill in the appropriate
values in `secrets.template.coffee` and rename it to `secrets.coffee`.

Next, assuming you have Node.js installed, run

```console
$ git clone https://github.com/jez/auditors-webhook
$ npm install

$ npm install -g nodemon coffee-script
```

Start the server:

```console
$ npm start
```

We need to use `ngrok` to expose our app to the Internet, so that GitHub can hit
it as a callback:

```console
$ brew install ngrok
$ ngrok 3000
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

And create a Webhook on GitHub for your repo by going to your organization or
repository settings, finding the "Webhooks & Services" tab. You'll need to set
Payload URL to `<your Forwarding URL>/postreceive` and click add (the defaults
are good for everything else).

That's it! You should be able to commit to that repo with `Auditors: <GitHub
username>` in the commit message and have issues be created.


## TODO

- [ ] There's no database right now, just config settings in `secrets.coffee`.
- [ ] It's not using the "Secret" field in the Webhook setup to verify that
  postreceives are actually coming from GitHub.
- [ ] Error handling and robustness has been overlooked.


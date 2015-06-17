_ = require 'underscore'

express = require 'express'
request = require 'request'
qs = require 'querystring'

router = express.Router()

# GET home page.
router.get '/', (req, res, next) ->
  res.render 'index'


# Redirect to GitHub login page
router.get '/login', (req, res, next) ->
  uri = 'https://github.com/login/oauth/authorize'
  params =
    scope: 'repo'
    client_id: process.env.GITHUB_CLIENT_ID

  res.redirect "#{uri}?#{qs.stringify params}"


# Acquire access token
router.get '/callback', (req, res, next) ->
  session_code = req.query.code

  uri = 'https://github.com/login/oauth/access_token'

  body =
    client_id: process.env.GITHUB_CLIENT_ID
    client_secret: process.env.GITHUB_CLIENT_SECRET
    code: session_code
    accept: 'application/json'

  callback = (err, _res, body) ->
    # TODO check that user has given us sufficent scope
    # TODO persist token in database
    if not err
      console.log body
      res.render 'index', { access_token: body.access_token }

  request.post {uri: uri, body: body, json: true}, callback


router.post '/postreceive', (req, res, next) ->
  repo = req.body.repository.full_name
  q = { access_token: process.env.GITHUB_ACCESS_TOKEN }
  uri = "https://api.github.com/repos/#{repo}/issues?#{qs.stringify(q)}"

  requestsToHandle = 0

  # Each event can signal multiple commits
  _.each req.body.commits, (commit, idx, arr) ->
    regex = /^Auditors:\s*(.*)\s*$/m
    m = commit.message

    auditorStr = m.match(regex)[1].trim()
    auditors = auditorStr.split /,?\s+/

    callback = (err, _res, body) ->
      # TODO handle and log errors better
      console.log err
      console.log body
      if _res.statusCode != 201
        res.sendStatus(_res.statusCode)
        res.end()
      else if requestsToHandle == 0
        res.end()

    # Each commit might assign multiple auditors
    _.each auditors, (auditor) ->
      console.log auditor
      cutOff = _.max [71, m.indexOf('\n')]

      params =
        title: "Audit for '#{m.slice(0, cutOff)}'"
        body: "#{m}\n\nCommit: #{commit.id.slice(0, 10)}"
        assignee: auditor
        labels: ['audit']

      console.log uri
      requestsToHandle += 1
      request.post {
        uri: uri,
        body: params,
        json: true,
        headers: { 'User-Agent': 'node.js' }
      }, callback


module.exports = router

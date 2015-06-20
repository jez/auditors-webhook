_ = require 'underscore'

request = require 'request'
async = require 'async'
qs = require 'querystring'

helpers = require './helpers'


# return an array of strings
parseAuditors = (commit) ->
  regex = /^Auditors:\s*(.*)\s*$/m
  m = commit.message

  # space-or-comma-separated list of auditors
  matches = m.match(regex)
  if matches
    auditorStr = matches[1].trim()
    auditorStr.split /,?\s+/
  else
    []


# create request to GitHub, calling 'asyncCallback' when done (to trigger next call)
# bind URI in a closure
createAuditIssueWrapper = (uri) ->
  (audit, asyncCallback) ->
    m = audit.commit.message
    cutOff = m.indexOf '\n'

    params =
      title: "Audit for '#{m.slice(0, cutOff)}'"
      body: """
        #{m.slice(cutOff)}

        __Discuss on the original commit's diff: #{audit.commit.id.slice(0, 10)}__
        /cc @#{audit.commit.author.username}
        """
      assignee: audit.auditor
      labels: ['audit']

    requestCb = (err, _res, body) ->
      if _res.statusCode != 201
        # error, abort all subsequent calls
        asyncCallback err, null
      else
        # Report new issue number
        asyncCallback null, body.number

    request.post {
      uri: uri,
      body: params,
      json: true,
      headers: { 'User-Agent': 'node.js' }
    }, requestCb


auditOpened = (req, res, next) ->
  return unless helpers.validateEvent 'push', req, res

  unless verifySignature req.body, req.headers['x-hub-signature']
    console.log 'Signatures invalid aborting.'
    res.status(403).end()

  repo = req.body.repository.full_name
  q = { access_token: process.env.GITHUB_ACCESS_TOKEN }
  uri = "https://api.github.com/repos/#{repo}/issues?#{qs.stringify q}"

  auditorCommitPair = _.map req.body.commits, (commit) ->
    # auditors = ['jez', '...']
    auditors = parseAuditors(commit)

    _.map auditors, (auditor) -> { commit: commit, auditor: auditor }
  # auditorCommitPair = [[{auditor, commit}, {...}], [{auditor, commit}, {...}], [...]]

  audits = _.flatten auditorCommitPair
  # audits = [{auditor, commit}, {auditor, commit}, {...}]

  createAuditIssue = createAuditIssueWrapper "#{issuesUri}"

  # serially fire off async issue-creation calls
  async.mapSeries audits, createAuditIssue, (err, issues) ->
    if err
      console.log err
      res.status(500).end()
    else
      res.end()


module.exports = auditOpened

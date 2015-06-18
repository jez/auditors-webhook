_ = require 'underscore'

request = require 'request'
async = require 'async'
qs = require 'querystring'


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
        asyncCallback err
      else
        # we're good, keep going with next call in async.eachSeries
        asyncCallback()

    request.post {
      uri: uri,
      body: params,
      json: true,
      headers: { 'User-Agent': 'node.js' }
    }, requestCb


postreceive = (req, res, next) ->
  # ping event
  if req.headers['X-GitHub-Event'] == 'ping'
    console.log 'ping event received.'
    console.log req.body.zen
    res.status(204).end()
    return

  repo = req.body.repository.full_name
  q = { access_token: process.env.GITHUB_ACCESS_TOKEN }
  uri = "https://api.github.com/repos/#{repo}/issues?#{qs.stringify(q)}"

  auditorCommitPair = _.map req.body.commits, (commit) ->
    # auditors = ['jez', '...']
    auditors = parseAuditors(commit)

    _.map auditors, (auditor) -> { commit: commit, auditor: auditor }
  # auditorCommitPair = [[{auditor, commit}, {...}], [{auditor, commit}, {...}], [...]]

  audits = _.flatten auditorCommitPair
  # audits = [{auditor, commit}, {auditor, commit}, {...}]

  createAuditIssue = createAuditIssueWrapper uri

  # serially fire off async issue-creation calls
  async.eachSeries audits, createAuditIssue, (err) ->
    if (err)
      console.log err
      res.statusCode 500
      res.end()
    else
      res.end()


module.exports = postreceive

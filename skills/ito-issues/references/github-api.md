# GitHub GraphQL API — Sub-issues & Blocked-by

## 取得 issue node_id

```bash
gh api graphql \
  -f query='query($owner:String!, $repo:String!, $number:Int!) {
    repository(owner:$owner, name:$repo) {
      issue(number:$number) { id }
    }
  }' \
  -f owner=OWNER -f repo=REPO -F number=ISSUE_NUM \
  --jq '.data.repository.issue.id'
```

## addSubIssue

將 task issue 掛到 parent issue 下。

```bash
PARENT_ID=$(gh api graphql \
  -f query='query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){issue(number:$number){id}}}' \
  -f owner=OWNER -f repo=REPO -F number=PARENT_NUM \
  --jq '.data.repository.issue.id')

CHILD_ID=$(gh api graphql \
  -f query='query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){issue(number:$number){id}}}' \
  -f owner=OWNER -f repo=REPO -F number=CHILD_NUM \
  --jq '.data.repository.issue.id')

gh api graphql \
  -f query='mutation($issueId:ID!,$subIssueId:ID!){
    addSubIssue(input:{issueId:$issueId, subIssueId:$subIssueId}){
      issue { number }
      subIssue { number }
    }
  }' \
  -f issueId="$PARENT_ID" -f subIssueId="$CHILD_ID"
```

## addBlockedBy

設定兩個 issue 之間的原生 blocked-by 關係。

```bash
# BLOCKED_ID = 被 block 的 issue（較晚執行的那個）
# BLOCKER_ID = block 它的 issue（必須先完成的那個）

gh api graphql \
  -f query='mutation($issueId:ID!,$blockingIssueId:ID!){
    addBlockedBy(input:{issueId:$issueId, blockingIssueId:$blockingIssueId}){
      issue { number }
      blockingIssue { number }
    }
  }' \
  -f issueId="$BLOCKED_ID" -f blockingIssueId="$BLOCKER_ID"
```
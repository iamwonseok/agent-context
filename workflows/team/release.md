# Team Release Workflow

> Coordinate a release from development to production.

## Overview

| Aspect | Value |
|--------|-------|
| **Scope** | Team/Squad |
| **Trigger** | Release scheduled |
| **Output** | Production deployment |
| **Duration** | Hours to 1 day |

---

## Release Phases

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   PREPARE   │ -> │   VERIFY    │ -> │   DEPLOY    │
│  (Freeze)   │    │   (Test)    │    │  (Release)  │
└─────────────┘    └─────────────┘    └─────────────┘
```

---

## Phase 1: Release Preparation

### Context Mapping
| Skill Input | Source |
|-------------|--------|
| `context` | Release scope + changelog |
| `artifacts` | Merged PRs, completed tickets |
| `goal` | Stable release candidate |

**Call Skill:** `skills/analyze.md`

### Preparation Checklist

1. **Code Freeze**
   - [ ] Feature freeze announced
   - [ ] Only bugfixes allowed after freeze
   - [ ] Release branch created

2. **Release Scope**
   | Feature/Fix | Ticket | Risk Level |
   |-------------|--------|------------|
   | {description} | {id} | {H/M/L} |

3. **Changelog Draft**
   ```markdown
   ## v{version} - {date}
   
   ### Added
   - {new feature}
   
   ### Changed
   - {modification}
   
   ### Fixed
   - {bug fix}
   ```

4. **Dependencies**
   - [ ] External service changes coordinated
   - [ ] Database migrations ready
   - [ ] Config changes documented

---

## Phase 2: Release Verification

### Context Mapping
| Skill Input | Source |
|-------------|--------|
| `implementation` | Release branch |
| `acceptance_criteria` | Release checklist |
| `test_scope` | Full regression + smoke |

**Call Skill:** `skills/test.md`

### Verification Checklist

1. **Automated Tests**
   - [ ] Unit tests: PASS
   - [ ] Integration tests: PASS
   - [ ] E2E tests: PASS

2. **Manual Verification**
   | Area | Tester | Status |
   |------|--------|--------|
   | {critical_path_1} | {name} | {OK/NG} |
   | {critical_path_2} | {name} | {OK/NG} |

3. **Staging Deployment**
   - [ ] Deployed to staging
   - [ ] Smoke test passed
   - [ ] No new errors in logs

4. **Sign-off**
   | Role | Name | Approved |
   |------|------|----------|
   | Tech Lead | {name} | [ ] |
   | QA | {name} | [ ] |
   | Product | {name} | [ ] |

---

## Phase 3: Production Deployment

### Pre-Deployment

1. **Communication**
   - [ ] Team notified
   - [ ] Stakeholders notified
   - [ ] Status page updated (if needed)

2. **Rollback Plan**
   ```
   Rollback Version: v{previous_version}
   Rollback Command: {command}
   Rollback Criteria: {when to rollback}
   ```

### Deployment

1. **Deploy Steps**
   ```bash
   # Example deployment sequence
   {deployment_commands}
   ```

2. **Health Checks**
   - [ ] Application starts successfully
   - [ ] Health endpoint returns OK
   - [ ] Key integrations responding

### Post-Deployment

1. **Monitoring (First 30 min)**
   - [ ] Error rate normal
   - [ ] Response time normal
   - [ ] No new error types

2. **Validation**
   - [ ] Smoke test on production
   - [ ] New features verified
   - [ ] Changelog published

---

## Completion Criteria

- [ ] Production deployment successful
- [ ] Monitoring stable for 30+ minutes
- [ ] Changelog published
- [ ] Release notes sent
- [ ] Tickets moved to Done

---

## Release Artifacts

| Artifact | Location | Owner |
|----------|----------|-------|
| Release Branch | `release/v{version}` | Tech Lead |
| Changelog | `CHANGELOG.md` | Tech Lead |
| Release Tag | `v{version}` | CI/CD |
| Release Notes | Email/Slack | Product |

---

## Rollback Procedure

If issues detected:

1. **Assess Severity**
   - P1: Immediate rollback
   - P2: Assess fix time vs rollback

2. **Execute Rollback**
   ```bash
   {rollback_commands}
   ```

3. **Notify**
   - Team channel
   - Stakeholders
   - Create incident ticket

4. **Post-mortem**
   - What went wrong
   - How to prevent
   - Follow-up actions

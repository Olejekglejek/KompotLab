# Public GitHub Repo Best Practices & Manual Configuration Checklist

This guide covers essential steps and best practices for configuring a public/open-source GitHub repository. Follow these instructions to maximize security, collaboration, and maintainability.

---

## 1. Protect the Main Branch
- Go to **Settings > Branches > Branch protection rules**
- Add a rule for `main`:
  - Require pull request reviews before merging
  - Require at least 1 approving review
  - Require status checks to pass before merging (add CI if available)
  - Require signed commits (optional, for security)
  - Restrict who can push to the branch (optional)
  - Do **not** allow force pushes or deletions

## 2. Enable Auto-Delete Branches After Merge
- Go to **Settings > General**
- Enable **"Automatically delete head branches"**

## 3. Enable Security Features
- Go to **Settings > Security**
  - Enable **Secret scanning**
  - Enable **Secret scanning push protection**
  - Enable **Dependabot alerts and updates**
  - Enable **Code scanning** (set up GitHub Actions or use default)

## 4. Set Repository Metadata
- Add a clear **description** and **homepage URL** in **Settings > General**
- Add relevant **topics** (e.g., `homelab`, `ansible`, `proxmox`) in **Settings > General**

## 5. Enable Collaboration Features
- Enable **Issues**, **Discussions**, and **Wiki** in **Settings > General**

## 6. Add CODEOWNERS File
- Create a `.github/CODEOWNERS` file to define who reviews/approves PRs for specific paths
- Example:
  ```
  * @your-github-username
  ```

## 7. Add Issue and PR Templates
- Create `.github/ISSUE_TEMPLATE/` and `.github/PULL_REQUEST_TEMPLATE.md` for consistent contributions
- See [GitHub Docs: Issue and PR templates](https://docs.github.com/en/github/building-a-strong-community/setting-up-issue-templates-for-your-repository)

## 8. Set Up Dependabot
- Add `.github/dependabot.yml` to automate dependency updates
- See [Dependabot Docs](https://docs.github.com/en/code-security/supply-chain-security/keeping-your-dependencies-updated-automatically)

## 9. Approve Your Own PRs (if solo maintainer)
- You can approve your own PRs unless branch protection requires non-author reviews
- If blocked, temporarily relax review requirements or use admin privileges

## 10. Add a License
- Add a clear `LICENSE` file (MIT, Apache 2.0, etc.)

## 11. Add a README
- Ensure your `README.md` is clear, up-to-date, and includes setup instructions

## 12. Add a Contributing Guide
- Add `CONTRIBUTING.md` to help others contribute

## 13. Add a Code of Conduct
- Add `CODE_OF_CONDUCT.md` for community standards

---

## Useful Links
- [GitHub Security Best Practices](https://docs.github.com/en/code-security)
- [GitHub Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/branch-protection-rules)
- [GitHub Community Standards](https://github.com/communities)

---

**Tip:** For automation, consider using the [gh CLI](https://cli.github.com/) or GitHub REST API, but manual configuration is recommended for most settings unless you manage many repos.

---

Feel free to copy/paste this checklist into your repo or share with collaborators!

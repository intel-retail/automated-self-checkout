## Pull requests

Please adhere to the coding conventions used throughout the project. If in doubt, consult the
[Effective Go](https://golang.org/doc/effective_go.html) style guide.

Adhering to the following process is the best way to get your work included in the project:

1. [Fork](https://help.github.com/articles/fork-a-repo/) the project, clone your fork, and configure
   the remotes:

   ```bash
   # Clone your fork of the repo into the current directory
   git clone https://github.com/<your-username>/automated-self-checkout.git

   # Navigate to the newly cloned directory
   cd automated-self-checkout

   # Assign the original repo to a remote called "upstream"
   git remote add upstream https://github.com/intel-retail/automated-self-checkout.git
   ```

2. If you cloned a while ago, get the latest changes from upstream:

   ```bash
   git checkout main
   git pull --rebase upstream main
   ```

3. Create a new issue branch from `main` using the naming convention `I-[issue-number]` to
   help us keep track of your contribution scope:

   ```bash
   git checkout -b I-[issue-number]
   ```

4. Commit your changes in logical chunks. When you are ready to commit, make sure to write a Good
   Commit Message™ by consulting the [Commit Message Guidelines](#commit-message-guidelines)  following the conventional commit standard.
   

   Note that every commit you make must be signed. By signing off your work you indicate that you
   are accepting the [Developer Certificate of Origin](https://developercertificate.org/).

   Use your real name (sorry, no pseudonyms or anonymous contributions). If you set your `user.name`
   and `user.email` git configs, you can sign your commit automatically with `git commit -s`.

5. Locally merge (or rebase) the upstream development branch into your issue branch:

   ```bash
   git pull --rebase upstream main
   ```

6. Push your issue branch up to your fork:

   ```bash
   git push origin I-[issue-number]
   ```

7. [Open a Pull Request](https://help.github.com/articles/using-pull-requests/) with a clear title
   and detailed description.

## Pull Requests practices

* PR author is responsible to merge its own PR after review has been done and CI has passed.
* When merging, make sure git linear history is preserved. PR author should select a merge option (`Rebase and merge` or `Squash and merge`) based on which option will fit the best to the git linear history.
* PR topic should follow the same guidelines as the header of the [Git Commit Message](#commit-message-format)

## <a name="commit"></a> Commit Message Guidelines

The git commit messages for this project follow the conventional commit format guideline. This leads to more readable messages that are easy to follow when looking through the project history.

### Commit Message Format
Each commit message consists of a **header**, a **body** and a **footer**. The header has a special format that includes a **type**, a **scope** and a **subject**:

```
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

The **header** with **type** is mandatory.  The **scope** of the header is optional as far as the automated PR checks are concerned, but be advised that PR reviewers **may request** you provide an applicable scope.

Any line of the commit message should not be longer 72 characters! This allows the message to be easier to read on GitHub as well as in various git tools.

The footer should contain a reference to an Azure Boards ticket (e.g. AB#[number]).

Example 1:
```
feat(telemetry): Add new MQTT events

Events are now emitted over various /mps topics on MQTT for success/failures 
as they occur throughout the service.

Resolves: AB#2222
```


### Revert
If the commit reverts a previous commit, it should begin with `revert: `, followed by the header of the reverted commit. In the body it should say: `This reverts commit <hash>.`, where the hash is the SHA of the commit being reverted.

### Type

Must be one of the following:

* **feat**: A new feature
* **fix**: A bug fix
* **docs**: Documentation only changes
* **style**: Changes that do not affect the meaning of the code (white-space, formatting, etc)
* **refactor**: A code change that neither fixes a bug nor adds a feature
* **perf**: A code change that improves performance
* **test**: Adding missing tests or correcting existing tests
* **build**: Changes that affect the CI/CD pipeline or build system or external dependencies (example scopes: travis, jenkins, makefile)
* **ci**: Changes provided by DevOps for CI purposes.
* **revert**: Reverts a previous commit.

### Scope

Should be one of the following:
Modules:
* **cli**: A change or addition to application interface
* **config**: A change or addition to service configuration
* **deps**: A change or addition to dependencies (primarily used by dependabot)
* **deps-dev**: A change or addition to developer dependencies (primarily used by dependabot)
* **docker**: A change or addition to docker file or composition
* **gh-actions**: A change or addition to GitHub actions
* **heci**: A change or addition to heci functionality
* **lib**: A change or addition that affects RPC built as a library
* **lme**: A change or addition to local management engine functionality
* **lms**: A change or addition to local management service functionality
* **lmx**: A change or addition to both lme and lms functionality
* **pthi**: A change or addition to pthi functionality
* **rps**: A change or addition to interactions with Remote Provisioning Server
* **sample**: A change or addition to the sample application
* **utils**: A change or addition to the utility functions
* *no scope*:  If no scope is provided, it is assumed the PR does not apply to the above scopes

### Body
Just as in the **subject**, use the imperative, present tense: "change" not "changed" nor "changes".
Here is detailed guideline on how to write the body of the commit message ([Reference](https://chris.beams.io/posts/git-commit/)):
```
More detailed explanatory text, if necessary. Wrap it to about 72
characters or so. In some contexts, the first line is treated as the
subject of the commit and the rest of the text as the body. The
blank line separating the summary from the body is critical (unless
you omit the body entirely); various tools like `log`, `shortlog`
and `rebase` can get confused if you run the two together.

Explain the problem that this commit is solving. Focus on why you
are making this change as opposed to how (the code explains that).
Are there side effects or other unintuitive consequences of this
change? Here's the place to explain them.

Further paragraphs come after blank lines.

 - Bullet points are okay, too

 - Typically a hyphen or asterisk is used for the bullet, preceded
   by a single space, with blank lines in between, but conventions
   vary here
```

### Footer

The footer should contain a reference to JIRA ticket (e.g. SL6-0000) that this commit **Closes** or **Resolves**.
The footer should contain any information about **Breaking Changes**.

**Breaking Changes** should start with the word `BREAKING CHANGE:` with a space or two newlines.

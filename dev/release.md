# Release Instruction

1. Prepare release pull request with changes necessary to create new version of Helm operator
   (update version, names, description, creation date),
   see [example pull request](https://github.com/SumoLogic/sumologic-kubernetes-collection-helm-operator/pull/35).

2. Create the release tag for commit with Helm Chart version change, e.g.

   ```bash
   git tag -a v2.1.1-0-rc.0 -m "Release v2.1.1-0-rc.0"
   ```

3. Push the release tag, e.g.

   ```bash
   git push origin v2.1.1-0-rc.0
   ```

4. For major and minor version change prepare release branch, e.g.

    ```bash
    git checkout -b release-v2.1.0
    git push origin release-v2.1.0
    ```

5. Cut the release

   - Go to https://github.com/SumoLogic/sumologic-kubernetes-collection-helm-operator/releases and click "Draft a new release".
   - Compare changes since the last release.
   - Prepare release notes.

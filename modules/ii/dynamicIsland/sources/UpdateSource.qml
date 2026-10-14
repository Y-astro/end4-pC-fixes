pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services

/**
 * The shell has an update waiting.
 *
 * Present for as long as the checkout is behind its remote branch, which can be days:
 * so it lives in an auxiliary bubble (or beside the clock), and only takes the island's
 * centre once, to say that an update turned up.
 *
 * "Once" is per remote commit. A live reload re-creates this object and the update is
 * still the same one, so what was already announced is kept across reloads; a new
 * commit landing on the branch is news again.
 */
ContinuousSource {
    id: source

    activityId: "update"

    condition: false
    payload: ""
}

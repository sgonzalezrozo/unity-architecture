#!/usr/bin/env bash
# Tests and builds the analyzers, and keeps the prebuilt copy in analyzers/prebuilt up to date.
# With a Unity project, also installs them there.
# Usage: analyzers/build.sh [unity-project] [assembly-folder]
# The default folder is Assets/Client, so the rules apply to the Client assembly only.
# Commit analyzers/prebuilt after a change: install.sh copies that DLL into projects without needing .NET.
set -eu

HERE="$(cd "$(dirname "$0")" && pwd)"
PROJECT="${1:-}"
FOLDER="${2:-Assets/Client}"
NAME="UnityArchitecture.Analyzers"

dotnet test "$HERE/$NAME.Tests/$NAME.Tests.csproj" --nologo
dotnet build "$HERE/$NAME/$NAME.csproj" -c Release --nologo

mkdir -p "$HERE/prebuilt"
cp "$HERE/$NAME/bin/Release/netstandard2.0/$NAME.dll" "$HERE/prebuilt/$NAME.dll"
echo "Updated $HERE/prebuilt/$NAME.dll"

if [ -n "$PROJECT" ]; then
    TARGET="$PROJECT/$FOLDER/Analyzers"
    mkdir -p "$TARGET"
    cp "$HERE/prebuilt/$NAME.dll" "$TARGET/$NAME.dll"
    cp "$HERE/dll.meta.template" "$TARGET/$NAME.dll.meta"
    echo "Installed in $TARGET"
fi

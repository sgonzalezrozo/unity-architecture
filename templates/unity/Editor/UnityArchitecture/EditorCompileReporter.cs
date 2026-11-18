using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEditor.Compilation;
using UnityEngine;

namespace UnityArchitecture.Editor
{
    /// <summary>
    /// Writes the result of every script compile to Logs/verify/editor-compile.json, so the Claude Code Stop hook can
    /// check the build while the Editor is open, when verify.sh can't run.
    /// </summary>
    [InitializeOnLoad]
    internal static class EditorCompileReporter
    {
        private const string REPORT_FILE = "editor-compile.json";

        private static readonly List<string> errors = new();

        static EditorCompileReporter()
        {
            CompilationPipeline.compilationStarted += OnCompilationStarted;
            CompilationPipeline.assemblyCompilationFinished += OnAssemblyCompilationFinished;
            CompilationPipeline.compilationFinished += OnCompilationFinished;
        }

        private static void OnCompilationStarted(object context)
        {
            errors.Clear();
            Write(true);
        }

        private static void OnAssemblyCompilationFinished(string assemblyPath, CompilerMessage[] messages)
        {
            foreach (CompilerMessage message in messages)
            {
                if (message.type == CompilerMessageType.Error)
                    errors.Add(message.message);
            }
        }

        private static void OnCompilationFinished(object context)
            => Write(false);

        private static void Write(bool compiling)
        {
            CompileReport report = new()
            {
                compiling = compiling,
                finishedAtUnixSeconds = DateTimeOffset.UtcNow.ToUnixTimeSeconds(),
                errorCount = errors.Count,
                errors = errors.ToArray()
            };
            VerifyReports.Write(REPORT_FILE, JsonUtility.ToJson(report, true));
        }

        [Serializable]
        private class CompileReport
        {
            public bool compiling;
            public long finishedAtUnixSeconds;
            public int errorCount;
            public string[] errors;
        }
    }

    public static class VerifyReports
    {
        // Logs/ sits next to Assets/, outside the asset database, so writing it never triggers an import.
        private static readonly string Folder = Path.Combine(Directory.GetCurrentDirectory(), "Logs", "verify");

        public static void Write(string fileName, string json)
        {
            try
            {
                Directory.CreateDirectory(Folder);
                File.WriteAllText(Path.Combine(Folder, fileName), json);
            }
            catch (IOException exception)
            {
                Debug.LogWarning($"[UnityArchitecture] Couldn't write {fileName}: {exception.Message}");
            }
        }
    }
}

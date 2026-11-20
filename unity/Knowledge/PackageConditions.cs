using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;

namespace UnityArchitecture.Knowledge
{
    /// <summary>
    /// Conditional blocks inside a .md, so a rule shows only the part for the installed tool:
    /// <c>&lt;!-- if: com.x.package --&gt;</c>, <c>&lt;!-- if-not: com.x.package --&gt;</c>,
    /// <c>&lt;!-- else --&gt;</c> and <c>&lt;!-- endif --&gt;</c>, each on its own line. They can nest.
    /// The name can also be a capability id from .ai/capabilities.json (<c>&lt;!-- if: uiScroller --&gt;</c>).
    /// With showAll every branch is shown and only the markers are removed.
    /// </summary>
    internal static class PackageConditions
    {
        private static readonly Regex IfRx = new Regex(@"^\s*<!--\s*if(-not)?:\s*([\w.\-]+)\s*-->\s*$");
        private static readonly Regex ElseRx = new Regex(@"^\s*<!--\s*else\s*-->\s*$");
        private static readonly Regex EndRx = new Regex(@"^\s*<!--\s*endif\s*-->\s*$");

        public static string Apply(string markdown, Dictionary<string, string> installedPackages, bool showAll)
        {
            if (string.IsNullOrEmpty(markdown) || markdown.IndexOf("<!--") < 0)
                return markdown;

            string[] lines = markdown.Replace("\r\n", "\n").Split('\n');
            var output = new StringBuilder(markdown.Length);
            var visibleStack = new Stack<bool>();
            var branchStack = new Stack<bool>();
            bool visible = true;

            for (int i = 0; i < lines.Length; i++)
            {
                Match condition = IfRx.Match(lines[i]);
                if (condition.Success)
                {
                    bool installed = installedPackages.ContainsKey(condition.Groups[2].Value);
                    bool branch = showAll || (condition.Groups[1].Success ? !installed : installed);
                    visibleStack.Push(visible);
                    branchStack.Push(branch);
                    visible = visible && branch;
                    continue;
                }

                if (ElseRx.IsMatch(lines[i]) && branchStack.Count > 0)
                {
                    visible = visibleStack.Peek() && (showAll || !branchStack.Peek());
                    continue;
                }

                if (EndRx.IsMatch(lines[i]) && visibleStack.Count > 0)
                {
                    visible = visibleStack.Pop();
                    branchStack.Pop();
                    continue;
                }

                if (visible)
                    output.Append(lines[i]).Append('\n');
            }

            return output.ToString();
        }
    }
}

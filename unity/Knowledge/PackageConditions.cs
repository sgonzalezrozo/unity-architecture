using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;

namespace UnityArchitecture.Knowledge
{
    /// <summary>
    /// Bloques condicionales dentro de un .md, para que una regla muestre solo la parte del tool instalado:
    /// <c>&lt;!-- if: com.x.package --&gt;</c>, <c>&lt;!-- if-not: com.x.package --&gt;</c>,
    /// <c>&lt;!-- else --&gt;</c> y <c>&lt;!-- endif --&gt;</c>, cada uno en su propia línea. Se pueden anidar.
    /// Con showAll se ven todas las ramas y solo se quitan los marcadores.
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

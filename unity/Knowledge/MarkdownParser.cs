using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;
using UnityEngine;

namespace UnityArchitecture.Knowledge
{
    internal enum MdBlockType
    {
        Heading,
        Paragraph,
        ListItem,
        Code,
        Callout,
        Table,
        Rule,
        Image,
        Flow
    }

    internal enum CalloutKind
    {
        Quote,
        Note,
        Tip,
        Important,
        Warning,
        Caution,
        Do,
        Dont,
        Rule,
        Example
    }

    internal sealed class FlowStep
    {
        public string label;
        public Color color;
    }

    /// <summary>Un enlace dentro de un texto: dónde está (en el texto con etiquetas y sin ellas) y a dónde lleva.</summary>
    internal sealed class MdLink
    {
        public string target;
        public int start;
        public int end;
        public int visibleStart;
        public int visibleEnd;
    }

    internal sealed class MdBlock
    {
        public MdBlockType type;
        public int level;
        public string text;
        public string raw;
        public string language;
        public string marker;
        public bool ordered;
        public int checkState = -1;

        public CalloutKind callout;
        public string title;
        public List<MdBlock> children;

        public List<MdLink> links;

        public string[] header;
        public List<string[]> rows;
        public List<MdLink>[] headerLinks;
        public List<List<MdLink>[]> rowLinks;
        public TextAnchor[] aligns;

        public string path;

        public List<List<FlowStep>> flowRows;

        // Cache de layout (tablas / flow) por ancho
        public float cachedWidth = -1f;
        public float[] cachedColumnWidths;
        public float[] cachedRowHeights;
        public float cachedHeight;
    }

    /// <summary>
    /// Convierte Markdown (subconjunto GitHub) en bloques listos para dibujar con IMGUI.
    /// Soporta: encabezados, párrafos, listas (anidadas, numeradas, checklist), código con resaltado,
    /// citas y callouts ([!NOTE], [!TIP], [!WARNING], [!DO], [!DONT]...), tablas, separadores,
    /// imágenes y diagramas ```flow.
    /// </summary>
    internal static class MarkdownParser
    {
        public const string RULE_LINK_PREFIX = "rule:";

        private static readonly Regex RuleIdRx = new Regex(@"^(?:[A-Z]{2,6}-\d{2}|UA\d{4})$");
        private static readonly Regex RichTagRx = new Regex(@"</?(?:b|i|color|size|material|quad)(?:=[^>]*)?>");
        private static readonly Regex HeadingRx = new Regex(@"^(#{1,6})\s+(.*?)\s*#*\s*$");
        private static readonly Regex RuleRx = new Regex(@"^\s{0,3}([-*_])(\s*\1){2,}\s*$");
        private static readonly Regex ImageRx = new Regex(@"^!\[(.*?)\]\(\s*<?([^)>""]+?)>?(?:\s+""(.*?)"")?\s*\)\s*$");
        private static readonly Regex ListRx = new Regex(@"^(\s*)([-*+]|\d+[.)])\s+(?:\[( |x|X)\]\s+)?(.*)$");
        private static readonly Regex FenceRx = new Regex(@"^\s*(```|~~~)\s*([\w#+.-]*)");
        private static readonly Regex TableSepRx = new Regex(@"^\s*\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)*\|?\s*$");
        private static readonly Regex CalloutRx = new Regex(@"^\[!(\w+)\]\s*(.*)$");

        private static readonly Regex EscapeRx = new Regex(@"\\([\\`*_{}\[\]()#+\-.!|~=<>])");
        private static readonly Regex CodeSpanRx = new Regex(@"(`+)\s?(.+?)\s?\1");
        private static readonly Regex LinkRx = new Regex(@"(?<!!)\[([^\]]+)\]\(([^)\s]+)(?:\s+""[^""]*"")?\)");
        private static readonly Regex BoldRx = new Regex(@"(\*\*|__)(?=\S)(.+?)(?<=\S)\1");
        private static readonly Regex ItalicStarRx = new Regex(@"(?<![\*\w])\*(?=\S)([^*]+?)(?<=\S)\*(?![\*\w])");
        private static readonly Regex ItalicUnderRx = new Regex(@"(?<![_\w])_(?=\S)([^_]+?)(?<=\S)_(?![_\w])");
        private static readonly Regex StrikeRx = new Regex(@"~~(.+?)~~");
        private static readonly Regex HighlightRx = new Regex(@"==(?=\S)(.+?)(?<=\S)==");
        private static readonly Regex BrRx = new Regex(@"<br\s*/?>", RegexOptions.IgnoreCase);
        private static readonly Regex TokenRx = new Regex("\u0001(\\d+)\u0002");

        private static readonly Regex CSharpRx = new Regex(
            @"(?<comment>//[^\n]*|/\*[\s\S]*?\*/)" +
            @"|(?<str>\$?@?""(?:[^""\\\n]|\\.)*""|'(?:[^'\\\n]|\\.)')" +
            @"|(?<kw>\b(?:public|private|protected|internal|static|readonly|const|sealed|abstract|virtual|override|class|struct|interface|enum|namespace|using|new|return|if|else|for|foreach|while|do|switch|case|break|continue|default|void|var|int|float|double|bool|string|char|long|byte|object|true|false|null|this|base|event|async|await|in|out|ref|is|as|typeof|nameof|get|set|throw|try|catch|finally|partial|where)\b)" +
            @"|(?<num>\b\d+(?:\.\d+)?[fFdDmM]?\b)" +
            @"|(?<attr>(?<=\[)[A-Z]\w*(?=[\]\(]))" +
            @"|(?<method>\b[A-Za-z_]\w*(?=\s*\())" +
            @"|(?<type>\b[A-Z]\w*\b)");

        private static readonly Regex GenericCodeRx = new Regex(
            @"(?<comment>//[^\n]*|#[^\n]*|/\*[\s\S]*?\*/)" +
            @"|(?<str>""(?:[^""\\\n]|\\.)*""|'(?:[^'\\\n]|\\.)*')" +
            @"|(?<kw>\b(?:true|false|null)\b)" +
            @"|(?<num>\b\d+(?:\.\d+)?\b)");

        public static List<MdBlock> Parse(string markdown, MdTheme theme)
        {
            var blocks = new List<MdBlock>();
            if (string.IsNullOrEmpty(markdown))
                return blocks;

            string normalized = markdown.Replace("\r\n", "\n").Replace("\t", "    ");
            string[] lines = normalized.Split('\n');
            ParseLines(lines, blocks, theme);
            return blocks;
        }

        private static void ParseLines(string[] lines, List<MdBlock> blocks, MdTheme theme)
        {
            var paragraph = new StringBuilder();
            var orderedCounters = new int[8];
            bool inComment = false;
            int i = 0;

            while (i < lines.Length)
            {
                string line = lines[i];
                string trimmed = line.Trim();

                if (inComment)
                {
                    if (trimmed.Contains("-->"))
                        inComment = false;
                    i++;
                    continue;
                }

                if (trimmed.StartsWith("<!--"))
                {
                    FlushParagraph(paragraph, blocks, theme);
                    inComment = !trimmed.Contains("-->");
                    i++;
                    continue;
                }

                if (trimmed.Length == 0)
                {
                    FlushParagraph(paragraph, blocks, theme);
                    i++;
                    continue;
                }

                Match fence = FenceRx.Match(line);
                if (fence.Success)
                {
                    FlushParagraph(paragraph, blocks, theme);
                    ResetCounters(orderedCounters);
                    i = ParseFence(lines, i, fence, blocks, theme);
                    continue;
                }

                Match heading = HeadingRx.Match(trimmed);
                if (heading.Success)
                {
                    FlushParagraph(paragraph, blocks, theme);
                    ResetCounters(orderedCounters);
                    blocks.Add(new MdBlock
                    {
                        type = MdBlockType.Heading,
                        level = heading.Groups[1].Value.Length,
                        text = FormatInline(heading.Groups[2].Value, theme),
                        raw = heading.Groups[2].Value
                    });
                    i++;
                    continue;
                }

                if (RuleRx.IsMatch(line))
                {
                    FlushParagraph(paragraph, blocks, theme);
                    ResetCounters(orderedCounters);
                    blocks.Add(new MdBlock { type = MdBlockType.Rule });
                    i++;
                    continue;
                }

                Match image = ImageRx.Match(trimmed);
                if (image.Success)
                {
                    FlushParagraph(paragraph, blocks, theme);
                    string caption = image.Groups[3].Success && image.Groups[3].Value.Length > 0
                        ? image.Groups[3].Value
                        : image.Groups[1].Value;
                    blocks.Add(new MdBlock
                    {
                        type = MdBlockType.Image,
                        path = image.Groups[2].Value.Trim(),
                        text = FormatInline(caption, theme)
                    });
                    i++;
                    continue;
                }

                if (trimmed.StartsWith(">"))
                {
                    FlushParagraph(paragraph, blocks, theme);
                    ResetCounters(orderedCounters);
                    i = ParseQuote(lines, i, blocks, theme);
                    continue;
                }

                if (trimmed.StartsWith("|") && i + 1 < lines.Length && TableSepRx.IsMatch(lines[i + 1]))
                {
                    FlushParagraph(paragraph, blocks, theme);
                    ResetCounters(orderedCounters);
                    i = ParseTable(lines, i, blocks, theme);
                    continue;
                }

                Match listItem = ListRx.Match(line);
                if (listItem.Success)
                {
                    FlushParagraph(paragraph, blocks, theme);
                    i = ParseListItem(lines, i, listItem, orderedCounters, blocks, theme);
                    continue;
                }

                if (paragraph.Length > 0 && paragraph[paragraph.Length - 1] != '\n')
                    paragraph.Append(' ');

                bool hardBreak = line.EndsWith("  ") || trimmed.EndsWith("\\");
                paragraph.Append(trimmed.EndsWith("\\") ? trimmed.Substring(0, trimmed.Length - 1) : trimmed);
                if (hardBreak)
                    paragraph.Append('\n');
                i++;
            }

            FlushParagraph(paragraph, blocks, theme);
        }

        private static void ResetCounters(int[] counters)
        {
            for (int i = 0; i < counters.Length; i++)
                counters[i] = 0;
        }

        private static void FlushParagraph(StringBuilder paragraph, List<MdBlock> blocks, MdTheme theme)
        {
            if (paragraph.Length == 0)
                return;

            string raw = paragraph.ToString().TrimEnd('\n');
            string formatted = FormatInline(raw, theme, out List<MdLink> links);
            blocks.Add(new MdBlock
            {
                type = MdBlockType.Paragraph,
                raw = raw,
                text = formatted,
                links = links
            });
            paragraph.Clear();
        }

        private static int ParseFence(string[] lines, int start, Match fence, List<MdBlock> blocks, MdTheme theme)
        {
            string fenceToken = fence.Groups[1].Value;
            string language = fence.Groups[2].Value.Trim().ToLowerInvariant();
            var code = new StringBuilder();
            int i = start + 1;

            while (i < lines.Length)
            {
                if (lines[i].TrimStart().StartsWith(fenceToken))
                {
                    i++;
                    break;
                }

                code.Append(lines[i]).Append('\n');
                i++;
            }

            string raw = code.ToString().TrimEnd('\n');

            if (language == "flow" || language == "flujo")
            {
                blocks.Add(new MdBlock { type = MdBlockType.Flow, flowRows = ParseFlow(raw, theme), raw = raw });
                return i;
            }

            blocks.Add(new MdBlock
            {
                type = MdBlockType.Code,
                language = language,
                raw = raw,
                text = Highlight(raw, language, theme)
            });
            return i;
        }

        private static int ParseQuote(string[] lines, int start, List<MdBlock> blocks, MdTheme theme)
        {
            var inner = new List<string>();
            int i = start;
            while (i < lines.Length)
            {
                string trimmed = lines[i].TrimStart();
                if (!trimmed.StartsWith(">"))
                    break;

                string content = trimmed.Substring(1);
                if (content.StartsWith(" "))
                    content = content.Substring(1);
                inner.Add(content);
                i++;
            }

            var block = new MdBlock { type = MdBlockType.Callout, callout = CalloutKind.Quote };

            if (inner.Count > 0)
            {
                Match callout = CalloutRx.Match(inner[0].Trim());
                if (callout.Success && TryGetCalloutKind(callout.Groups[1].Value, out CalloutKind kind))
                {
                    block.callout = kind;
                    string customTitle = callout.Groups[2].Value.Trim();
                    block.title = FormatInline(customTitle.Length > 0 ? customTitle : DefaultCalloutTitle(kind), theme);
                    inner.RemoveAt(0);
                }
            }

            block.children = new List<MdBlock>();
            ParseLines(inner.ToArray(), block.children, theme);
            blocks.Add(block);
            return i;
        }

        private static int ParseTable(string[] lines, int start, List<MdBlock> blocks, MdTheme theme)
        {
            string[] headerRaw = SplitTableRow(lines[start]);
            string[] sepCells = SplitTableRow(lines[start + 1]);

            var block = new MdBlock
            {
                type = MdBlockType.Table,
                header = new string[headerRaw.Length],
                rows = new List<string[]>(),
                headerLinks = new List<MdLink>[headerRaw.Length],
                rowLinks = new List<List<MdLink>[]>(),
                aligns = new TextAnchor[headerRaw.Length]
            };

            for (int c = 0; c < headerRaw.Length; c++)
            {
                block.header[c] = FormatInline(headerRaw[c], theme, out block.headerLinks[c]);
                string sep = c < sepCells.Length ? sepCells[c].Trim() : string.Empty;
                bool left = sep.StartsWith(":");
                bool right = sep.EndsWith(":");
                block.aligns[c] = left && right ? TextAnchor.UpperCenter
                    : right ? TextAnchor.UpperRight
                    : TextAnchor.UpperLeft;
            }

            int i = start + 2;
            while (i < lines.Length)
            {
                string trimmed = lines[i].Trim();
                if (trimmed.Length == 0 || !trimmed.Contains("|"))
                    break;

                string[] cells = SplitTableRow(trimmed);
                var row = new string[headerRaw.Length];
                var rowLinks = new List<MdLink>[headerRaw.Length];
                for (int c = 0; c < row.Length; c++)
                    row[c] = c < cells.Length ? FormatInline(cells[c], theme, out rowLinks[c]) : string.Empty;
                block.rows.Add(row);
                block.rowLinks.Add(rowLinks);
                i++;
            }

            blocks.Add(block);
            return i;
        }

        private static string[] SplitTableRow(string line)
        {
            string trimmed = line.Trim();
            if (trimmed.StartsWith("|"))
                trimmed = trimmed.Substring(1);
            if (trimmed.EndsWith("|") && !trimmed.EndsWith("\\|"))
                trimmed = trimmed.Substring(0, trimmed.Length - 1);

            var cells = new List<string>();
            var current = new StringBuilder();
            bool inCode = false;

            for (int i = 0; i < trimmed.Length; i++)
            {
                char ch = trimmed[i];
                if (ch == '\\' && i + 1 < trimmed.Length && trimmed[i + 1] == '|')
                {
                    current.Append('|');
                    i++;
                    continue;
                }

                if (ch == '`')
                    inCode = !inCode;

                if (ch == '|' && !inCode)
                {
                    cells.Add(current.ToString().Trim());
                    current.Clear();
                    continue;
                }

                current.Append(ch);
            }

            cells.Add(current.ToString().Trim());
            return cells.ToArray();
        }

        private static int ParseListItem(string[] lines, int start, Match match, int[] counters, List<MdBlock> blocks, MdTheme theme)
        {
            int indentSpaces = match.Groups[1].Value.Length;
            int level = Mathf.Clamp(indentSpaces / 2, 0, counters.Length - 1);
            string markerRaw = match.Groups[2].Value;
            bool ordered = char.IsDigit(markerRaw[0]);

            var text = new StringBuilder(match.Groups[4].Value.Trim());
            int i = start + 1;

            // Líneas de continuación (indentadas, sin ser otro ítem ni otro bloque)
            while (i < lines.Length)
            {
                string next = lines[i];
                string nextTrimmed = next.Trim();
                if (nextTrimmed.Length == 0 || ListRx.IsMatch(next) || FenceRx.IsMatch(next))
                    break;

                int nextIndent = next.Length - next.TrimStart().Length;
                if (nextIndent <= indentSpaces || nextTrimmed.StartsWith(">") || nextTrimmed.StartsWith("|"))
                    break;

                text.Append(' ').Append(nextTrimmed);
                i++;
            }

            for (int l = level + 1; l < counters.Length; l++)
                counters[l] = 0;

            string marker = null;
            if (ordered)
            {
                counters[level]++;
                marker = counters[level] + ".";
            }

            int checkState = -1;
            if (match.Groups[3].Success)
                checkState = match.Groups[3].Value.Trim().Length > 0 ? 1 : 0;

            string formatted = FormatInline(text.ToString(), theme, out List<MdLink> links);
            blocks.Add(new MdBlock
            {
                type = MdBlockType.ListItem,
                links = links,
                level = level,
                ordered = ordered,
                marker = marker,
                checkState = checkState,
                raw = text.ToString(),
                text = formatted
            });

            return i;
        }

        private static List<List<FlowStep>> ParseFlow(string raw, MdTheme theme)
        {
            var rows = new List<List<FlowStep>>();
            string[] lines = raw.Split('\n');

            for (int l = 0; l < lines.Length; l++)
            {
                string line = lines[l].Trim();
                if (line.Length == 0)
                    continue;

                string[] parts = Regex.Split(line, @"\s*(?:->|→|=>)\s*");
                var row = new List<FlowStep>();
                for (int p = 0; p < parts.Length; p++)
                {
                    string part = parts[p].Trim();
                    if (part.Length == 0)
                        continue;
                    row.Add(ParseFlowStep(part, theme));
                }

                if (row.Count > 0)
                    rows.Add(row);
            }

            return rows;
        }

        private static FlowStep ParseFlowStep(string part, MdTheme theme)
        {
            string label = part;
            string colorName = null;

            int colon = part.LastIndexOf(':');
            if (colon > 0 && colon < part.Length - 1)
            {
                string candidate = part.Substring(colon + 1).Trim();
                if (theme.TryGetNamedColor(candidate, out _))
                {
                    colorName = candidate;
                    label = part.Substring(0, colon).Trim();
                }
            }

            Color color;
            if (colorName == null || !theme.TryGetNamedColor(colorName, out color))
                color = theme.GuessFlowColor(label);

            return new FlowStep { label = FormatInline(label, theme), color = color };
        }

        public static bool TryGetCalloutKind(string name, out CalloutKind kind)
        {
            switch (name.ToUpperInvariant())
            {
                case "NOTE":
                case "NOTA":
                case "INFO":
                    kind = CalloutKind.Note;
                    return true;
                case "TIP":
                case "CONSEJO":
                case "TRUCO":
                    kind = CalloutKind.Tip;
                    return true;
                case "IMPORTANT":
                case "IMPORTANTE":
                    kind = CalloutKind.Important;
                    return true;
                case "WARNING":
                case "ATENCION":
                case "ATENCIÓN":
                case "CUIDADO":
                    kind = CalloutKind.Warning;
                    return true;
                case "CAUTION":
                case "DANGER":
                case "PELIGRO":
                    kind = CalloutKind.Caution;
                    return true;
                case "DO":
                case "HACER":
                case "SI":
                case "SÍ":
                case "BIEN":
                    kind = CalloutKind.Do;
                    return true;
                case "DONT":
                case "DON'T":
                case "NO":
                case "EVITAR":
                case "MAL":
                    kind = CalloutKind.Dont;
                    return true;
                case "RULE":
                case "REGLA":
                    kind = CalloutKind.Rule;
                    return true;
                case "EXAMPLE":
                case "EJEMPLO":
                    kind = CalloutKind.Example;
                    return true;
                default:
                    kind = CalloutKind.Quote;
                    return false;
            }
        }

        private static string DefaultCalloutTitle(CalloutKind kind)
        {
            switch (kind)
            {
                case CalloutKind.Note: return "Nota";
                case CalloutKind.Tip: return "Consejo";
                case CalloutKind.Important: return "Importante";
                case CalloutKind.Warning: return "Atención";
                case CalloutKind.Caution: return "Peligro";
                case CalloutKind.Do: return "Haz esto";
                case CalloutKind.Dont: return "Evita esto";
                case CalloutKind.Rule: return "Regla";
                case CalloutKind.Example: return "Ejemplo";
                default: return string.Empty;
            }
        }

        // ---------------------------------------------------------------- Inline

        public static string FormatInline(string text, MdTheme theme)
        {
            return FormatInline(text, theme, out _);
        }

        /// <summary>
        /// Convierte el Markdown en línea a rich text de IMGUI. Los enlaces (<c>[texto](doc:id)</c>, URLs y los
        /// IDs de regla en código, como <c>`VIEW-03`</c>) se devuelven con su posición en el texto final.
        /// </summary>
        public static string FormatInline(string text, MdTheme theme, out List<MdLink> links)
        {
            links = null;
            if (string.IsNullOrEmpty(text))
                return string.Empty;

            var tokens = new List<string>();
            var targets = new List<string>();

            string result = EscapeRx.Replace(text, m => AddToken(tokens, m.Groups[1].Value));
            result = CodeSpanRx.Replace(result, m => FormatCodeSpan(m.Groups[2].Value, theme, tokens, targets));
            result = BrRx.Replace(result, "\n");
            result = LinkRx.Replace(result, m => WrapLink(
                $"<color=#{theme.LinkHex}>{m.Groups[1].Value}</color>", m.Groups[2].Value, targets));
            result = BoldRx.Replace(result, "<b>$2</b>");
            result = ItalicStarRx.Replace(result, "<i>$1</i>");
            result = ItalicUnderRx.Replace(result, "<i>$1</i>");
            result = StrikeRx.Replace(result, $"<color=#{theme.MutedHex}>$1</color>");
            result = HighlightRx.Replace(result, $"<color=#{theme.HighlightHex}><b>$1</b></color>");

            // Los tokens pueden contener otros tokens (link con código): restaurar hasta estabilizar.
            for (int pass = 0; pass < 3 && result.IndexOf('\u0001') >= 0; pass++)
                result = TokenRx.Replace(result, m => tokens[int.Parse(m.Groups[1].Value)]);

            return targets.Count == 0 ? result : ExtractLinks(result, targets, out links);
        }

        private static string FormatCodeSpan(string code, MdTheme theme, List<string> tokens, List<string> targets)
        {
            string token = AddToken(tokens, $"<color=#{theme.InlineCodeHex}>{code}</color>");
            return RuleIdRx.IsMatch(code) ? WrapLink(token, RULE_LINK_PREFIX + code, targets) : token;
        }

        private static string WrapLink(string content, string target, List<string> targets)
        {
            targets.Add(target);
            return "\u0003" + (targets.Count - 1) + "\u0004" + content + "\u0005";
        }

        /// <summary>Quita los marcadores de enlace y anota dónde empieza y acaba cada uno en el texto final.</summary>
        private static string ExtractLinks(string marked, List<string> targets, out List<MdLink> links)
        {
            links = new List<MdLink>();
            var output = new StringBuilder(marked.Length);
            var open = new Stack<MdLink>();

            for (int i = 0; i < marked.Length; i++)
            {
                char ch = marked[i];
                if (ch == '\u0003')
                {
                    int close = marked.IndexOf('\u0004', i);
                    int targetIndex = int.Parse(marked.Substring(i + 1, close - i - 1));
                    open.Push(new MdLink { target = targets[targetIndex], start = output.Length });
                    i = close;
                    continue;
                }

                if (ch == '\u0005' && open.Count > 0)
                {
                    MdLink link = open.Pop();
                    link.end = output.Length;
                    links.Add(link);
                    continue;
                }

                output.Append(ch);
            }

            string result = output.ToString();
            for (int i = 0; i < links.Count; i++)
            {
                links[i].visibleStart = VisibleIndex(result, links[i].start);
                links[i].visibleEnd = VisibleIndex(result, links[i].end);
            }
            return result;
        }

        /// <summary>Posición contando solo caracteres visibles (sin las etiquetas de rich text).</summary>
        private static int VisibleIndex(string richText, int rawIndex)
        {
            int visible = 0;
            for (int i = 0; i < rawIndex && i < richText.Length; i++)
            {
                if (richText[i] == '<')
                {
                    Match tag = RichTagRx.Match(richText, i);
                    if (tag.Success && tag.Index == i)
                    {
                        i += tag.Length - 1;
                        continue;
                    }
                }
                visible++;
            }
            return visible;
        }

        private static string AddToken(List<string> tokens, string value)
        {
            tokens.Add(value);
            return "\u0001" + (tokens.Count - 1) + "\u0002";
        }

        // ---------------------------------------------------------------- Syntax highlight

        private static string Highlight(string code, string language, MdTheme theme)
        {
            if (string.IsNullOrEmpty(code))
                return string.Empty;

            Regex rx;
            switch (language)
            {
                case "csharp":
                case "cs":
                case "c#":
                case "java":
                case "js":
                case "javascript":
                case "ts":
                case "typescript":
                    rx = CSharpRx;
                    break;
                case "json":
                case "yaml":
                case "yml":
                case "bash":
                case "sh":
                case "shell":
                case "python":
                case "py":
                    rx = GenericCodeRx;
                    break;
                default:
                    return code;
            }

            return rx.Replace(code, m => ColorizeMatch(m, theme));
        }

        private static string ColorizeMatch(Match m, MdTheme theme)
        {
            string hex =
                m.Groups["comment"].Success ? theme.SyntaxCommentHex :
                m.Groups["str"].Success ? theme.SyntaxStringHex :
                m.Groups["kw"].Success ? theme.SyntaxKeywordHex :
                m.Groups["num"].Success ? theme.SyntaxNumberHex :
                Has(m, "attr") ? theme.SyntaxTypeHex :
                Has(m, "method") ? theme.SyntaxMethodHex :
                Has(m, "type") ? theme.SyntaxTypeHex :
                null;

            return hex == null ? m.Value : $"<color=#{hex}>{m.Value}</color>";
        }

        private static bool Has(Match m, string group)
        {
            Group g = m.Groups[group];
            return g != null && g.Success;
        }
    }
}

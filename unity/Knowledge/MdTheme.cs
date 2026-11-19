using UnityEngine;

namespace UnityArchitecture.Knowledge
{
    /// <summary>
    /// The Markdown viewer's palette. One for the dark skin and one for the light skin.
    /// </summary>
    internal sealed class MdTheme
    {
        public readonly bool dark;

        public readonly Color text;
        public readonly Color muted;
        public readonly Color accent;
        public readonly Color heading3;
        public readonly Color divider;
        public readonly Color codeBackground;
        public readonly Color codeHeader;
        public readonly Color codeBorder;
        public readonly Color tableHeader;
        public readonly Color tableRowAlt;
        public readonly Color tableBorder;
        public readonly Color cardBackground;
        public readonly Color cardHeaderHover;
        public readonly Color cardBorder;
        public readonly Color categoryText;

        public readonly Color blue;
        public readonly Color green;
        public readonly Color orange;
        public readonly Color red;
        public readonly Color purple;
        public readonly Color teal;
        public readonly Color yellow;
        public readonly Color pink;
        public readonly Color gray;

        public readonly string InlineCodeHex;
        public readonly string LinkHex;
        public readonly string MutedHex;
        public readonly string HighlightHex;
        public readonly string SyntaxKeywordHex;
        public readonly string SyntaxTypeHex;
        public readonly string SyntaxMethodHex;
        public readonly string SyntaxStringHex;
        public readonly string SyntaxNumberHex;
        public readonly string SyntaxCommentHex;

        public MdTheme(bool dark)
        {
            this.dark = dark;

            if (dark)
            {
                text = Hex("D4D4D4");
                muted = Hex("8B949E");
                accent = Hex("58A6FF");
                heading3 = Hex("79C0FF");
                divider = new Color(1f, 1f, 1f, 0.10f);
                codeBackground = Hex("161B22");
                codeHeader = Hex("21262D");
                codeBorder = Hex("30363D");
                tableHeader = Hex("2D333B");
                tableRowAlt = new Color(1f, 1f, 1f, 0.03f);
                tableBorder = Hex("3D444D");
                cardBackground = new Color(1f, 1f, 1f, 0.035f);
                cardHeaderHover = new Color(1f, 1f, 1f, 0.05f);
                cardBorder = new Color(0f, 0f, 0f, 0.35f);
                categoryText = Hex("8B949E");

                blue = Hex("4493F8");
                green = Hex("3FB950");
                orange = Hex("F0883E");
                red = Hex("F85149");
                purple = Hex("AB7DF8");
                teal = Hex("39C5CF");
                yellow = Hex("D29922");
                pink = Hex("DB61A2");
                gray = Hex("8B949E");

                InlineCodeHex = "FFA657";
                LinkHex = "58A6FF";
                MutedHex = "8B949E";
                HighlightHex = "E3B341";
                SyntaxKeywordHex = "FF7B72";
                SyntaxTypeHex = "FFA657";
                SyntaxMethodHex = "D2A8FF";
                SyntaxStringHex = "A5D6FF";
                SyntaxNumberHex = "79C0FF";
                SyntaxCommentHex = "8B949E";
            }
            else
            {
                text = Hex("1F2328");
                muted = Hex("59636E");
                accent = Hex("0969DA");
                heading3 = Hex("0550AE");
                divider = new Color(0f, 0f, 0f, 0.12f);
                codeBackground = Hex("F6F8FA");
                codeHeader = Hex("EAEEF2");
                codeBorder = Hex("D0D7DE");
                tableHeader = Hex("E6EAEF");
                tableRowAlt = new Color(0f, 0f, 0f, 0.025f);
                tableBorder = Hex("C4CCD5");
                cardBackground = new Color(1f, 1f, 1f, 0.45f);
                cardHeaderHover = new Color(0f, 0f, 0f, 0.04f);
                cardBorder = new Color(0f, 0f, 0f, 0.18f);
                categoryText = Hex("59636E");

                blue = Hex("0969DA");
                green = Hex("1A7F37");
                orange = Hex("BC4C00");
                red = Hex("CF222E");
                purple = Hex("8250DF");
                teal = Hex("1B7C83");
                yellow = Hex("9A6700");
                pink = Hex("BF3989");
                gray = Hex("59636E");

                InlineCodeHex = "953800";
                LinkHex = "0969DA";
                MutedHex = "59636E";
                HighlightHex = "9A6700";
                SyntaxKeywordHex = "CF222E";
                SyntaxTypeHex = "953800";
                SyntaxMethodHex = "8250DF";
                SyntaxStringHex = "0A3069";
                SyntaxNumberHex = "0550AE";
                SyntaxCommentHex = "6E7781";
            }
        }

        public Color CalloutColor(CalloutKind kind)
        {
            switch (kind)
            {
                case CalloutKind.Note: return blue;
                case CalloutKind.Tip: return green;
                case CalloutKind.Important: return purple;
                case CalloutKind.Warning: return yellow;
                case CalloutKind.Caution: return red;
                case CalloutKind.Do: return green;
                case CalloutKind.Dont: return red;
                case CalloutKind.Rule: return teal;
                case CalloutKind.Example: return pink;
                default: return gray;
            }
        }

        public bool TryGetNamedColor(string name, out Color color)
        {
            switch (name.Trim().ToLowerInvariant())
            {
                case "blue": case "azul": color = blue; return true;
                case "green": case "verde": color = green; return true;
                case "orange": case "naranja": color = orange; return true;
                case "red": case "rojo": color = red; return true;
                case "purple": case "morado": case "violeta": color = purple; return true;
                case "teal": case "cian": color = teal; return true;
                case "yellow": case "amarillo": color = yellow; return true;
                case "pink": case "rosa": color = pink; return true;
                case "gray": case "grey": case "gris": color = gray; return true;
            }

            string hex = name.Trim();
            if (hex.StartsWith("#") && ColorUtility.TryParseHtmlString(hex, out color))
                return true;

            color = gray;
            return false;
        }

        /// <summary>Default colors for the steps of a ```flow diagram, by MVC layer.</summary>
        public Color GuessFlowColor(string label)
        {
            string l = label.ToLowerInvariant();
            if (l.Contains("model") || l.Contains("modelo") || l.Contains("module")) return blue;
            if (l.Contains("view") || l.Contains("vista") || l.Contains("render")) return green;
            if (l.Contains("controller") || l.Contains("controlador")) return orange;
            if (l.Contains("input") || l.Contains("entrada") || l.Contains("click")) return purple;
            if (l.Contains("connector") || l.Contains("backend") || l.Contains("server")) return teal;
            if (l.Contains("event") || l.Contains("evento")) return yellow;
            return gray;
        }

        public Color EntryColor(string hexOrName, int index)
        {
            if (!string.IsNullOrEmpty(hexOrName) && TryGetNamedColor(hexOrName, out Color named))
                return named;

            Color[] cycle = { blue, green, orange, purple, teal, pink, yellow, red };
            return cycle[Mathf.Abs(index) % cycle.Length];
        }

        private static Color Hex(string hex)
        {
            ColorUtility.TryParseHtmlString("#" + hex, out Color c);
            return c;
        }
    }
}

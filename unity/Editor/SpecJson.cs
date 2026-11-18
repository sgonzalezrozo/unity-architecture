using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;

namespace UnityArchitecture.Prefabs
{
    /// <summary>
    /// A small JSON reader for prefab specs: objects become Dictionary&lt;string, object&gt;, arrays List&lt;object&gt;,
    /// numbers double. It has no dependencies and no depth limit, unlike JsonUtility with recursive types.
    /// </summary>
    internal sealed class SpecJson
    {
        private readonly string text;
        private int position;

        private SpecJson(string text)
        {
            this.text = text;
        }

        public static object Parse(string json)
        {
            if (string.IsNullOrWhiteSpace(json))
                throw new FormatException("The spec is empty.");

            SpecJson reader = new(json);
            object value = reader.ReadValue();
            reader.SkipWhitespace();
            if (reader.position < json.Length)
                throw reader.Error("Unexpected text after the end of the spec");

            return value;
        }

        private object ReadValue()
        {
            SkipWhitespace();
            if (position >= text.Length)
                throw Error("The spec ends too early");

            char current = text[position];
            switch (current)
            {
                case '{':
                    return ReadObject();
                case '[':
                    return ReadArray();
                case '"':
                    return ReadString();
                case 't':
                    return ReadWord("true", true);
                case 'f':
                    return ReadWord("false", false);
                case 'n':
                    return ReadWord("null", null);
                default:
                    return ReadNumber();
            }
        }

        private Dictionary<string, object> ReadObject()
        {
            Dictionary<string, object> result = new();
            position++;
            SkipWhitespace();
            if (TryRead('}'))
                return result;

            do
            {
                SkipWhitespace();
                string key = ReadString();
                SkipWhitespace();
                Expect(':');
                result[key] = ReadValue();
                SkipWhitespace();
            }
            while (TryRead(','));

            Expect('}');
            return result;
        }

        private List<object> ReadArray()
        {
            List<object> result = new();
            position++;
            SkipWhitespace();
            if (TryRead(']'))
                return result;

            do
            {
                result.Add(ReadValue());
                SkipWhitespace();
            }
            while (TryRead(','));

            Expect(']');
            return result;
        }

        private string ReadString()
        {
            Expect('"');
            StringBuilder builder = new();
            while (position < text.Length && text[position] != '"')
            {
                char current = text[position++];
                if (current == '\\')
                    builder.Append(ReadEscape());
                else
                    builder.Append(current);
            }

            Expect('"');
            return builder.ToString();
        }

        private char ReadEscape()
        {
            if (position >= text.Length)
                throw Error("The spec ends inside a string");

            char escaped = text[position++];
            switch (escaped)
            {
                case 'n':
                    return '\n';
                case 't':
                    return '\t';
                case 'r':
                    return '\r';
                case 'b':
                    return '\b';
                case 'f':
                    return '\f';
                case 'u':
                    return ReadUnicode();
                default:
                    return escaped;
            }
        }

        private char ReadUnicode()
        {
            if (position + 4 > text.Length)
                throw Error("Incomplete \\u escape");

            string hex = text.Substring(position, 4);
            position += 4;
            return (char)int.Parse(hex, NumberStyles.HexNumber, CultureInfo.InvariantCulture);
        }

        private double ReadNumber()
        {
            int start = position;
            while (position < text.Length && "+-0123456789.eE".IndexOf(text[position]) >= 0)
                position++;

            string number = text.Substring(start, position - start);
            if (!double.TryParse(number, NumberStyles.Float, CultureInfo.InvariantCulture, out double value))
                throw Error($"Expected a value, found '{(number.Length > 0 ? number : text[start].ToString())}'");

            return value;
        }

        private object ReadWord(string word, object value)
        {
            if (string.CompareOrdinal(text, position, word, 0, word.Length) != 0)
                throw Error($"Expected {word}");

            position += word.Length;
            return value;
        }

        private void SkipWhitespace()
        {
            while (position < text.Length && char.IsWhiteSpace(text[position]))
                position++;
        }

        private bool TryRead(char expected)
        {
            if (position >= text.Length || text[position] != expected)
                return false;

            position++;
            return true;
        }

        private void Expect(char expected)
        {
            if (!TryRead(expected))
                throw Error($"Expected '{expected}'");
        }

        private FormatException Error(string message)
        {
            int line = 1;
            int column = 1;
            for (int i = 0; i < position && i < text.Length; i++)
            {
                if (text[i] == '\n')
                {
                    line++;
                    column = 1;
                }
                else
                {
                    column++;
                }
            }

            return new FormatException($"{message} at line {line}, column {column} of the spec.");
        }
    }
}

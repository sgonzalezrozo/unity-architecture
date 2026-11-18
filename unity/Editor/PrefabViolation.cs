namespace UnityArchitecture.Prefabs
{
    /// <summary>One broken prefab rule: which rule, on which object, and what to change. A warning doesn't fail.</summary>
    public readonly struct PrefabViolation
    {
        public readonly string RuleId;
        public readonly string ObjectPath;
        public readonly string Message;
        public readonly bool IsWarning;

        public PrefabViolation(string ruleId, string objectPath, string message, bool isWarning)
        {
            RuleId = ruleId;
            ObjectPath = objectPath;
            Message = message;
            IsWarning = isWarning;
        }

        public override string ToString()
        {
            string level = IsWarning ? "warning" : "error";
            return $"{ObjectPath}: {level} {RuleId}: {Message}";
        }
    }
}

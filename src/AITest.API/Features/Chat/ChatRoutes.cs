namespace AITest.API.Features.Chat
{
    /// <summary>
    /// Centralized route definitions for the Chat feature.
    /// Keeps route paths consistent and refactor-safe.
    /// </summary>
    public static class ChatRoutes
    {
        /// <summary>
        /// Base path for all Chat-related endpoints.
        /// </summary>
        public const string Base = "/chat";

        /// <summary>
        /// Relative path for Azure chat handler (used within the MapGroup).
        /// </summary>
        public const string Azure = "azure";

        /// <summary>
        /// Relative path for local chat handler (used within the MapGroup).
        /// </summary>
        public const string Local = "local";

        /// <summary>
        /// Relative path to the responses to the chat messages.
        /// </summary>
        public const string Responses = "responses";

        /// <summary>
        /// Fully qualified path to Azure chat (useful for OpenAPI or non-grouped maps).
        /// </summary>
        public static string AzureFull => $"{Base}/{Azure}";

        /// <summary>
        /// Fully qualified path to local chat (useful for OpenAPI or non-grouped maps).
        /// </summary>
        public static string LocalFull => $"{Base}/{Local}";
    }
}

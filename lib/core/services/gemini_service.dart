import 'ai_service.dart';

/// Legacy service wrapper class maintaining backward compatibility.
/// All AI calls are routed through [AiService] via the Cloudflare Worker to Groq.
class GeminiService extends AiService {
  GeminiService({super.httpClient, super.auth});
}

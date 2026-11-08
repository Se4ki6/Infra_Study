using System.Text;
using System.Text.Json;

namespace S3StsDownload.Services;

/// <summary>JWT のペイロードから、AWS 側の設定合わせに必要なクレームだけを取り出す。</summary>
public sealed record JwtClaims(
    string? Issuer,
    string? Audience,
    string? Subject,
    string? ObjectId,
    string? TenantId,
    string? AppId,
    DateTimeOffset? ExpiresAt);

/// <summary>
/// アクセストークンのペイロードを *検証せずに* デコードするだけのヘルパー。
///
/// 用途は AWS の OIDC プロバイダ設定 (issuer / aud) と信頼ポリシー (sub) を
/// 実際の値に合わせるための確認だけ。認可の判断には絶対に使わないこと
/// (署名を検証していないため)。実際の検証は AWS STS 側が行う。
/// </summary>
public static class JwtInspector
{
    public static JwtClaims ReadClaims(string jwt)
    {
        var segments = jwt.Split('.');
        if (segments.Length < 2)
        {
            return new JwtClaims(null, null, null, null, null, null, null);
        }

        using var document = JsonDocument.Parse(Base64UrlDecode(segments[1]));
        var root = document.RootElement;

        return new JwtClaims(
            Issuer:     GetString(root, "iss"),
            Audience:   GetString(root, "aud"),
            Subject:    GetString(root, "sub"),
            ObjectId:   GetString(root, "oid"),
            TenantId:   GetString(root, "tid"),
            AppId:      GetString(root, "appid") ?? GetString(root, "azp"),
            ExpiresAt:  root.TryGetProperty("exp", out var exp) && exp.TryGetInt64(out var seconds)
                            ? DateTimeOffset.FromUnixTimeSeconds(seconds)
                            : null);
    }

    private static string? GetString(JsonElement root, string name)
    {
        if (!root.TryGetProperty(name, out var value))
        {
            return null;
        }

        // aud は配列で入ってくることがある
        return value.ValueKind switch
        {
            JsonValueKind.String => value.GetString(),
            JsonValueKind.Array  => string.Join(",", value.EnumerateArray().Select(e => e.GetString())),
            _                    => value.ToString(),
        };
    }

    private static byte[] Base64UrlDecode(string input)
    {
        var normalized = input.Replace('-', '+').Replace('_', '/');
        var padding = normalized.Length % 4;
        if (padding > 0)
        {
            normalized += new string('=', 4 - padding);
        }

        return Convert.FromBase64String(normalized);
    }
}

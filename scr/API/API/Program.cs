using System.Security.Claims;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();


var app = builder.Build();
//
// app.UseMiddleware<ContainerAppUserMiddleware>();
app.UseSwagger();
app.UseSwaggerUI();

app.MapGet("/test", (HttpRequest request, HttpContext context) =>
    {
        var headers = request.Headers.ToDictionary(x => x.Key, x => x.Value.ToString());

        // var claims = ClaimsPrincipalParser.Parse(request);

        //headers.Add("hasAdmin", claims.IsInRole("orders.admin").ToString());
        //foreach (var claimsClaim in claims.Claims) headers.Add(claimsClaim.Type, claimsClaim.Value);

        //headers.Add("userIsAdmin", context.User.IsInRole("orders.admin").ToString());


        return headers.Select(x => $"{x.Key} -  {x.Value}");
    })
    .WithName("GetWeatherForecast")
    .WithOpenApi();

app.Run();

public static class ClaimsPrincipalParser
{
    public static ClaimsPrincipal Parse(HttpRequest req)
    {
        var principal = new ClientPrincipal();

        if (req.Headers.TryGetValue("x-ms-client-principal", out var header))
        {
            var data = header[0];
            var decoded = Convert.FromBase64String(data);
            var json = Encoding.UTF8.GetString(decoded);
            principal = JsonSerializer.Deserialize<ClientPrincipal>(json,
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
        }

        var identity = new ClaimsIdentity(principal.IdentityProvider, principal.NameClaimType, principal.RoleClaimType);
        identity.AddClaims(principal.Claims.Select(c => new Claim(c.Type, c.Value)));

        return new ClaimsPrincipal(identity);
    }

    public class ClientPrincipalClaim
    {
        [JsonPropertyName("typ")] public string Type { get; set; }

        [JsonPropertyName("val")] public string Value { get; set; }
    }

    public class ClientPrincipal
    {
        [JsonPropertyName("auth_typ")] public string IdentityProvider { get; set; }

        [JsonPropertyName("name_typ")] public string NameClaimType { get; set; }

        [JsonPropertyName("role_typ")] public string RoleClaimType => "roles";

        [JsonPropertyName("claims")] public List<ClientPrincipalClaim> Claims { get; set; } = new();
    }
}

public class ContainerAppUserMiddleware
{
    private readonly RequestDelegate next;

    public ContainerAppUserMiddleware(RequestDelegate next) => this.next = next;

    public async Task Invoke(HttpContext context)
    {
        var newPrinciple = ClaimsPrincipalParser.Parse(context.Request);
        context.User = newPrinciple;

        await next(context);
    }
}
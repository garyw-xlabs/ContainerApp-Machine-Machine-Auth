using System.Net.Http.Headers;
using Azure.Core;
using Azure.Identity;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure the HTTP request pipeline.
app.UseSwagger();
app.UseSwaggerUI();


app.MapGet("/relay",
        async (IConfiguration configuration)
            =>
        {
            try
            {
                var credential = new DefaultAzureCredential();
                var token = credential.GetToken(
                    new TokenRequestContext(new[] { configuration.GetValue<string>("Api:AuthId") }));

                var httpClient = new HttpClient();
                httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("bearer", token.Token);
                httpClient.BaseAddress =
                    new Uri($"https://{configuration.GetValue<string>("Api:Uri")}/test");

                var response = await httpClient.GetAsync("/test");

                return await response.Content.ReadFromJsonAsync<List<string>>();
            }
            catch (Exception ex)
            {
                return new List<string> { ex.Message };
            }
        })
    .WithName("GetRelay")
    .WithOpenApi();

app.Run();
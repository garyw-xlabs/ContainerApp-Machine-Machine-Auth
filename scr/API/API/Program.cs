using Azure.Identity;
using Microsoft.Extensions.Options;

var builder = WebApplication.CreateBuilder(args);

var defaultAzureCredential = new DefaultAzureCredential();
builder.Services.AddAzureAppConfiguration();
builder.Configuration.AddAzureAppConfiguration(options =>
{
    options.Connect(new Uri(builder.Configuration["AZURE_APP_CONFIG_ENDPOINT"]), defaultAzureCredential)
        .ConfigureKeyVault(kv => { kv.SetCredential(defaultAzureCredential); })
        .ConfigureRefresh(c => { c.Register(builder.Configuration["AZURE_APP_CONFIG_SENTINAL_KEY"], true); });
});
builder.Services.Configure<AppConfigSettings>(builder.Configuration.GetSection("AppConfig"));
// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();


var app = builder.Build();
app.UseSwagger();
app.UseSwaggerUI();
app.UseAzureAppConfiguration();
app.MapGet("/settings",
        (HttpRequest request, IOptionsSnapshot<AppConfigSettings> configuration) => { return configuration; })
    .WithName("GetSettings")
    .WithOpenApi();

app.Run();

class AppConfigSettings
{
    public string Setting { get; set; }
}
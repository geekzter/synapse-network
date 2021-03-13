using System;
using System.Data;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace EW.Sql.Function
{
    public static class GetRows
    {
        [FunctionName("GetRows")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)] HttpRequest req,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");
            int rowsRetrieved = 0;

            string name = req.Query["name"];

            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody);
            name = name ?? data?.name;

            // Get the connection string from app settings and use it to create a connection.
            var str = Environment.GetEnvironmentVariable("CONNECTION_STRING");
            using (SqlConnection conn = new SqlConnection(str))
            {
                var query = "select top 100 * from dbo.Trip";

                conn.Open();
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {

                    IAsyncResult result = cmd.BeginExecuteReader(CommandBehavior.CloseConnection);

                    int count = 0;
                    while (!result.IsCompleted)
                    {
                        Console.WriteLine("Waiting ({0})", count++);
                        System.Threading.Thread.Sleep(100);
                    }

                    using (SqlDataReader reader = cmd.EndExecuteReader(result))
                    {
                        while (reader.Read())
                        {
                            rowsRetrieved++;
                            // for (int i = 0; i < reader.FieldCount; i++)
                            // {
                            //     Console.Write("{0}\t", reader.GetValue(i));
                            // }
                            // Console.WriteLine();
                        }
                    }
                }
            }
            log.LogInformation($"{rowsRetrieved} rows were retrieved");

            string responseMessage = string.IsNullOrEmpty(name)
                ? "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response."
                : $"Hello, {name}. This HTTP triggered function executed successfully.";

            return new OkObjectResult(responseMessage);
        }
    }
}


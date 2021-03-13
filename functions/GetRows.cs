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
        private static string GetConnectionString()
        {
            return Environment.GetEnvironmentVariable("CONNECTION_STRING");
        }

        [FunctionName("GetRows")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)] 
            // [HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = "v1/resource/{rowCount:int}")] 
            HttpRequest req,
            ILogger log//,
            //int rowCount
        )
        {
            log.LogInformation("C# HTTP trigger function processed a request.");
            int rowsRetrieved = 0;

            string name = null;// = req.Query["name"];

            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody);
            name = name ?? data?.name;

            try {
                using (SqlConnection conn = new SqlConnection(GetConnectionString()))
                {
                    var query = @"select top (@Count) * from dbo.Trip";

                    conn.Open();
                    using (SqlCommand cmd = new SqlCommand(query, conn))
                    {
                        cmd.Parameters.Add("@Count", SqlDbType.Int);
                        cmd.Parameters["@Count"].Value = 1000;
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
            }
            catch (SqlException ex)
            {
                Console.WriteLine("Error ({0}): {1}", ex.Number, ex.Message);
                throw;
            }
            catch (InvalidOperationException ex)
            {
                Console.WriteLine("Error: {0}", ex.Message);
                throw;
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: {0}", ex.Message);
                throw;
            }
            log.LogInformation($"{rowsRetrieved} rows were retrieved");

            string responseMessage = string.IsNullOrEmpty(name)
                ? "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response."
                : $"Hello, {name}. This HTTP triggered function executed successfully.";

            return new OkObjectResult(responseMessage);
        }
    }
}
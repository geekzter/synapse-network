using System;
using System.Collections.Generic;
using System.Data;
using System.Diagnostics;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;

namespace EW.Sql.Function
{
    public class GetRows
    {
        private const string TimerFormat = @"hh\:mm\:ss";

        private static string GetConnectionString()
        {
            return Environment.GetEnvironmentVariable("SYNAPSE_CONNECTION_STRING");
        }

        [FunctionName("GetRows")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", Route = "v1/top/{rowCount:int}")] 
            HttpRequest req,
            ILogger log,
            int rowCount = 100
        )
        {
            Stopwatch stopwatch = Stopwatch.StartNew();
            log.LogInformation("Start processing request: {0}",stopwatch.Elapsed.ToString(TimerFormat));
            int rowsRetrieved = 0;

            try {
                using (SqlConnection conn = new SqlConnection(GetConnectionString()))
                {
                    conn.Open();
                    log.LogInformation("Connection opened: {0}",stopwatch.Elapsed.ToString(TimerFormat));
                    using (SqlCommand cmd = CreateQueryCommand(conn, rowCount))
                    {
                        IAsyncResult result = cmd.BeginExecuteReader(CommandBehavior.CloseConnection);
                        log.LogInformation("Query submitted: {0}",stopwatch.Elapsed.ToString(TimerFormat));

                        while (!result.IsCompleted)
                        {
                            log.LogDebug("Waiting for result: {0}",stopwatch.Elapsed.ToString(TimerFormat));
                            System.Threading.Thread.Sleep(100);
                        }
                        log.LogInformation("Query completed: {0}",stopwatch.Elapsed.ToString(TimerFormat));

                        using (SqlDataReader reader = cmd.EndExecuteReader(result))
                        {
                            while (reader.Read())
                            {
                                if (rowsRetrieved == 0) {
                                    log.LogInformation("First bytes received {0}: ",stopwatch.Elapsed.ToString(TimerFormat));
                                }
                                rowsRetrieved++;

                                // Read all fields
                                for (int i = 0; i < reader.FieldCount; i++)
                                {
                                    reader.GetValue(i);
                                }
                            }
                        }
                        log.LogInformation("{0} rows spooled {0}: ",rowsRetrieved,stopwatch.Elapsed.ToString(TimerFormat));
                    }
                }
            }
            catch (Exception ex)
            {
                log.LogCritical(ex,ex.Message);

                // Rethrow exception
                throw;
            }
            
            string responseMessage = String.Format("{0} rows were retrieved in {1}",rowsRetrieved,stopwatch.Elapsed.ToString(TimerFormat));
            return new OkObjectResult(responseMessage);
        }

        private static SqlCommand CreateQueryCommand(SqlConnection connection, int rowCount)
        {
            var query = @"select top (@Count) * from dbo.Trip";
            SqlCommand command = new SqlCommand(query, connection);
            command.Parameters.Add("@Count", SqlDbType.Int);
            command.Parameters["@Count"].Value = Math.Min(rowCount,10000000);

            return command;
        }

        private static string FormatTimers(Dictionary<string, TimeSpan> timers) {
            string result = String.Empty;

            foreach (string snapshot in timers.Keys) {
                TimeSpan timer = timers[snapshot];
                string elapsed = timer.ToString(TimerFormat);
                result += String.Format("\n{0}: {1}",snapshot,elapsed);
            }

            return result;
        }

    }
}
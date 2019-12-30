﻿using System;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.Mvc;

namespace TeaWebApp.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class TeaController : ControllerBase
    {
        [HttpGet, HttpPost]
        public async Task<IActionResult> Invoke()
        {
            var response = new HttpResponseMessage(HttpStatusCode.OK);
            var strb = new StringBuilder();

            var dict = Environment.GetEnvironmentVariables();
            strb.AppendLine("--- Environments ---");
            foreach (var key in dict.Keys)
            {
                strb.AppendLine($"{key}={dict[key]}");
            }
            strb.AppendLine();

            strb.AppendLine("--- Headers ---");
            foreach (var header in Request.Headers)
            {
                strb.AppendLine($"{header.Key}: {header.Value}");
            }
            strb.AppendLine();

            strb.AppendLine("--- ifconfig.co ---");
            try
            {
                using (var client = new HttpClient())
                {
                    using (var resp = await client.GetAsync("http://ifconfig.co/ip"))
                    {
                        resp.EnsureSuccessStatusCode();
                        strb.AppendFormat("Outbound: {0}", await resp.Content.ReadAsStringAsync());
                    }
                }
            }
            catch (Exception ex)
            {
                strb.AppendLine($"Exception: {ex}");
            }
            strb.AppendLine();

            response.Content = new StringContent(strb.ToString(), Encoding.UTF8, "text/plain");
            return await Task.FromResult(new HttpResponseMessageResult(response));
        }

        public class HttpResponseMessageResult : IActionResult
        {
            private readonly HttpResponseMessage _responseMessage;

            public HttpResponseMessageResult(HttpResponseMessage responseMessage)
            {
                _responseMessage = responseMessage; // could add throw if null
            }

            public async Task ExecuteResultAsync(ActionContext context)
            {
                var response = context.HttpContext.Response;


                if (_responseMessage == null)
                {
                    var message = "Response message cannot be null";

                    throw new InvalidOperationException(message);
                }

                using (_responseMessage)
                {
                    response.StatusCode = (int)_responseMessage.StatusCode;

                    var responseFeature = context.HttpContext.Features.Get<IHttpResponseFeature>();
                    if (responseFeature != null)
                    {
                        responseFeature.ReasonPhrase = _responseMessage.ReasonPhrase;
                    }

                    var responseHeaders = _responseMessage.Headers;

                    // Ignore the Transfer-Encoding header if it is just "chunked".
                    // We let the host decide about whether the response should be chunked or not.
                    if (responseHeaders.TransferEncodingChunked == true &&
                        responseHeaders.TransferEncoding.Count == 1)
                    {
                        responseHeaders.TransferEncoding.Clear();
                    }

                    foreach (var header in responseHeaders)
                    {
                        response.Headers.Append(header.Key, header.Value.ToArray());
                    }

                    if (_responseMessage.Content != null)
                    {
                        var contentHeaders = _responseMessage.Content.Headers;

                        // Copy the response content headers only after ensuring they are complete.
                        // We ask for Content-Length first because HttpContent lazily computes this
                        // and only afterwards writes the value into the content headers.
                        var unused = contentHeaders.ContentLength;

                        foreach (var header in contentHeaders)
                        {
                            response.Headers.Append(header.Key, header.Value.ToArray());
                        }

                        await _responseMessage.Content.CopyToAsync(response.Body);
                    }
                }
            }
        }
    }
}

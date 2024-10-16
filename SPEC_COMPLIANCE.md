# Spec Compliance

## Metrics

| Spec Statement | Optional? | PR Raised | PR Merged | GitHub|
| ---------------|-----------|-----------|-----------|----|
| The API provides a way to set and get a global default MeterProvider. | X | X | X | --- |
| It is possible to create any number of MeterProviders. | X | X | X | --- |
| MeterProvider provides a way to get a Meter. |  | X | X | --- |
| get_meter accepts name, version and schema_url. |  |  |  | #1708 |
| get_meter accepts attributes. |  |  |  | #1709 |
| When an invalid name is specified a working Meter implementation is returned as a fallback. |  |  |  | #1710 |
| The fallback Meter name property keeps its original invalid value. | X |  |  | #1710 |
| Associate Meter with InstrumentationScope. |  | X | X | --- |
| Counter instrument is supported. |  | X |  | #1707 |
| AsynchronousCounter instrument is supported. |  | X |  | #1610 |
| Histogram instrument is supported. |  | X |  | #1707 |
| AsynchronousGauge instrument is supported. |  | X |  | #1610 |
| Gauge instrument is supported. |  |  |  | #1704 |
| UpDownCounter instrument is supported. |  | X |  | #1705 |
| AsynchronousUpDownCounter instrument is supported. |  | X |  | #1610 |
| Instruments have name |  | X | X | --- |
| Instruments have kind. |  | X | X | --- |
| Instruments have an optional unit of measure. |  | X | X | --- |
| Instruments have an optional description. |  | X | X | --- |
| A valid instrument MUST be created and warning SHOULD be emitted when multiple instruments are registered under the same Meter using the same name. |  | X |  | #1706 |
| Duplicate instrument registration name conflicts are resolved by using the first-seen for the stream name. |  |  |  | #1706 |
| It is possible to register two instruments with same name under different Meters. |  |  |  | #1706 |
| Instrument names conform to the specified syntax. |  |  |  | #1706 |
| Instrument units conform to the specified syntax. |  | X |  | #1706 |
| Instrument descriptions conform to the specified syntax. |  |  |  | #1706 |
| Instrument supports the advisory ExplicitBucketBoundaries parameter. |  | X |  | #1703 |
| Instrument supports the advisory Attributes parameter. |  |  |  | #1686 |
| All methods of MeterProvider are safe to be called concurrently. |  | X | X | --- |
| All methods of Meter are safe to be called concurrently. |  | X | X | --- |
| All methods of any instrument are safe to be called concurrently. |  |  |  | #1711 |
| MeterProvider allows a Resource to be specified. |  | X | X | --- |
| A specified Resource can be associated with all the produced metrics from any Meter from the MeterProvider. |  | X | X | --- |
| The supplied name, version and schema_url arguments passed to the MeterProvider are used to create an InstrumentationLibrary instance stored in the Meter. |  | X | X | --- |
| The supplied name, version and schema_url arguments passed to the MeterProvider are used to create an InstrumentationScope instance stored in the Meter. |  |  |  | #1708 |
| Configuration is managed solely by the MeterProvider. |  |  |  | #1716 |
| The MeterProvider provides methods to update the configuration | X |  |  | #1716 |
| The updated configuration applies to all already returned Meters. | if above |  |  | #1716 |
| There is a way to register Views with a MeterProvider. |  | X |  | #1604 |
| The View instrument selection criteria is as specified. |  | X |  | #1604 |
| The View instrument selection criteria supports wildcards. | X | X |  | #1604 |
| The View instrument selection criteria supports the match-all wildcard. |  | X |  | #1604 |
| The name of the View can be specified. |  | X |  | #1604 |
| The View allows configuring the name, description, attributes keys and aggregation of the resulting metric stream. |  | X |  | #1604 |
| The View allows configuring the exemplar reservoir of resulting metric stream. | X |  |  | |
| The SDK allows more than one View to be specified per instrument. | X | X |  | #1604 |
| The Drop aggregation is available. |  | X |  | #1604 |
| The Default aggregation is available. |  | X |  | |
| The Default aggregation uses the specified aggregation by instrument. |  | X |  | |
| The Sum aggregation is available. |  | X |  | |
| The LastValue aggregation is available. |  | X |  | #1604 |
| The ExplicitBucketHistogram aggregation is available. |  | X |  | |
| The ExponentialBucketHistogram aggregation is available. |  |  |  | #1722 |
| The metrics Reader implementation supports registering metric Exporters |  | X |  | |
| The metrics Reader implementation supports configuring the default aggregation on the basis of instrument kind. |  |  |  | #1723 |
| The metrics Reader implementation supports configuring the default temporality on the basis of instrument kind. |  |  |  | #1723 |
| The metrics Exporter has access to the aggregated metrics data (aggregated points, not raw measurements). |  | X |  | |
| The metrics Exporter export function can not be called concurrently from the same Exporter instance. |  | X |  | |
| The metrics Exporter export function does not block indefinitely. |  | X |  | |
| The metrics Exporter export function receives a batch of metrics. |  | X |  | |
| The metrics Exporter export function returns Success or Failure. |  | X |  | |
| The metrics Exporter provides a ForceFlush function. |  | X |  | |
| The metrics Exporter ForceFlush can inform the caller whether it succeeded, failed or timed out. |  | X |  | |
| The metrics Exporter provides a shutdown function. |  | X |  | |
| The metrics Exporter shutdown function do not block indefinitely. |  | X |  | |
| The metrics SDK samples Exemplars from measurements. |  | X |  | #1609 |
| Exemplar sampling can be disabled. |  | X |  | #1609 |
| The metrics SDK supports SDK-wide exemplar filter configuration |  | X |  | #1609 |
| The metrics SDK supports TraceBased exemplar filter |  | X |  | #1609 |
| The metrics SDK supports AlwaysOn exemplar filter |  | X |  | #1609 |
| The metrics SDK supports AlwaysOff exemplar filter |  | X |  | #1609 |
| Exemplars retain any attributes available in the measurement that are not preserved by aggregation or view configuration. |  |  |  | |
| Exemplars contain the associated trace id and span id of the active span in the Context when the measurement was taken. |  | X |  | #1609 |
| Exemplars contain the timestamp when the measurement was taken. |  | X |  | #1609 |
| The metrics SDK provides an ExemplarReservoir interface or extension point. |  |  |  | |
| An ExemplarReservoir has an offer method with access to the measurement value, attributes, Context and timestamp. |  | X |  | #1609 |
| The metrics SDK provides a SimpleFixedSizeExemplarReservoir that is used by default for all aggregations except ExplicitBucketHistogram. |  | X |  | #1609 |
| The metrics SDK provides an AlignedHistogramBucketExemplarReservoir that is used by default for ExplicitBucketHistogram aggregation. |  | X |  | #1609 |
| A metric Producer accepts an optional metric Filter |  |  |  | |
| The metric Reader implementation supports registering metric Filter and passing them its registered metric Producers |  |  |  | |
| The metric SDK's metric Producer implementations uses the metric Filter |  |  |  | |

